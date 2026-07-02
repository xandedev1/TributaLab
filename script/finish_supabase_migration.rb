#!/usr/bin/env ruby

require "active_record"
require "json"
require "pg"
require "timeout"
require "uri"
require_relative "../config/environment"

STDOUT.sync = true

SUPABASE_URL = ENV["SUPABASE_DATABASE_URL"].to_s
abort "Defina SUPABASE_DATABASE_URL antes de rodar." if SUPABASE_URL.empty?

EXCLUDED_TABLES = %w[
	schema_migrations
	ar_internal_metadata
	esocial_certificates
].freeze

def config_from_url(url)
	uri = URI.parse(url)
	{
		adapter: "postgresql",
		host: uri.host,
		port: uri.port || 5432,
		database: uri.path.to_s.delete_prefix("/").presence || "postgres",
		username: URI.decode_www_form_component(uri.user.to_s),
		password: URI.decode_www_form_component(uri.password.to_s)
	}
rescue URI::InvalidURIError
	nil
end

def candidate_configs(url)
	parsed = config_from_url(url)
	return [ url ] unless parsed

	candidates = []
	if parsed[:host].to_s.include?("pooler.supabase.com") && parsed[:username].to_s.start_with?("postgres.")
		project_ref = parsed[:username].split(".", 2).last
		candidates << parsed.merge(host: "db.#{project_ref}.supabase.co", username: "postgres", port: 5432)
	end
	candidates << parsed
	candidates
end

def pg_connect(config)
	if config.is_a?(Hash)
		PG.connect(
			host: config[:host],
			port: config[:port],
			dbname: config[:database],
			user: config[:username],
			password: config[:password],
			connect_timeout: 10
		)
	else
		PG.connect(config, connect_timeout: 10)
	end
end

def choose_remote_config(url)
	candidate_configs(url).each do |config|
		connection = pg_connect(config)
		connection.exec("SELECT 1")
		connection.close
		label = config.is_a?(Hash) && config[:host].to_s.start_with?("db.") ? "direta" : "pooler"
		puts "Conexao Supabase OK (#{label})."
		return config
	rescue PG::Error => error
		warn "Conexao Supabase falhou em candidato #{config.is_a?(Hash) ? config[:host] : 'url'}: #{error.message.lines.first&.strip}"
	end

	abort "Nenhuma conexao Supabase funcionou."
end

def establish_remote_active_record(config)
	ActiveRecord::Base.establish_connection(config)
	connection = ActiveRecord::Base.connection
	connection.execute("SET lock_timeout = '15s'")
	connection.execute("SET statement_timeout = '10min'")
	connection
end

def load_schema!(config)
	puts "Carregando schema no Supabase..."
	connection = establish_remote_active_record(config)
	ActiveRecord::Schema.verbose = false
	schema_path = File.expand_path("../db/schema.rb", __dir__)
	schema_source = File.read(schema_path).lines.reject do |line|
		line.match?(/^\s*(create_schema|enable_extension)\b/)
	end.join

	eval(schema_source, TOPLEVEL_BINDING, schema_path)

	connection.create_table(:schema_migrations, id: false, if_not_exists: true) do |table|
		table.string :version, null: false
	end
	unless connection.indexes(:schema_migrations).any? { |index| index.columns == [ "version" ] }
		connection.add_index :schema_migrations, :version, unique: true, name: "unique_schema_migrations"
	end

	connection.execute("TRUNCATE schema_migrations")
	versions = Dir.glob(File.expand_path("../db/migrate/*.rb", __dir__)).map { |path| File.basename(path).split("_").first }.sort
	versions.each do |version|
		connection.raw_connection.exec_params("INSERT INTO schema_migrations (version) VALUES ($1)", [ version ])
	end

	connection.create_table(:ar_internal_metadata, primary_key: :key, id: :string, if_not_exists: true) do |table|
		table.string :value
		table.datetime :created_at, null: false
		table.datetime :updated_at, null: false
	end
	now = Time.now.utc
	connection.raw_connection.exec_params(<<~SQL, [ "environment", "development", now, now ])
		INSERT INTO ar_internal_metadata (key, value, created_at, updated_at)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = EXCLUDED.updated_at
	SQL
	puts "Schema OK."
end

def quote_ident(connection, value)
	connection.escape_identifier(value.to_s)
end

def table_order(connection, tables)
	remaining = tables.to_h do |table|
		dependencies = connection.foreign_keys(table).map(&:to_table) & tables
		[ table, dependencies ]
	end
	ordered = []

	until remaining.empty?
		ready = remaining.select { |_table, dependencies| (dependencies - ordered).empty? }.keys
		ready = remaining.keys.sort if ready.empty?

		ready.sort.each do |table|
			ordered << table
			remaining.delete(table)
		end
	end

	ordered
end

def copy_data!(config)
	puts "Copiando dados..."
	ActiveRecord::Base.establish_connection(:development)
	local = ActiveRecord::Base.connection
	remote = pg_connect(config)
	remote.exec("SET lock_timeout = '15s'")
	remote.exec("SET statement_timeout = '10min'")

	tables = local.tables.reject { |table| EXCLUDED_TABLES.include?(table) || table.start_with?("solid_") }.sort
	ordered_tables = table_order(local, tables)
	quoted_tables = tables.map { |table| quote_ident(remote, table) }.join(", ")
	total_rows = 0

	remote.exec("BEGIN")
	begin
		remote.exec("TRUNCATE #{quoted_tables} RESTART IDENTITY CASCADE") if quoted_tables.present?

		ordered_tables.each do |table|
			columns = local.columns(table).map(&:name)
			next if columns.empty?

			quoted_table = quote_ident(remote, table)
			quoted_columns = columns.map { |column| quote_ident(remote, column) }.join(", ")
			placeholders = columns.each_index.map { |index| "$#{index + 1}" }.join(", ")
			insert_sql = "INSERT INTO #{quoted_table} (#{quoted_columns}) VALUES (#{placeholders})"
			order_clause = columns.include?("id") ? " ORDER BY #{local.quote_column_name("id")}" : ""
			rows = local.exec_query("SELECT #{columns.map { |column| local.quote_column_name(column) }.join(", ")} FROM #{local.quote_table_name(table)}#{order_clause}")

			rows.each do |row|
				values = columns.map do |column|
					value = row[column]
					value.is_a?(Hash) || value.is_a?(Array) ? JSON.generate(value) : value
				end
				remote.exec_params(insert_sql, values)
			end

			primary_key = local.primary_key(table)
			if primary_key.present? && columns.include?(primary_key)
				max_id = local.select_value("SELECT MAX(#{local.quote_column_name(primary_key)}) FROM #{local.quote_table_name(table)}").to_i
				remote.exec_params("SELECT setval(pg_get_serial_sequence($1, $2), $3, $4)", [ table, primary_key, [ max_id, 1 ].max, max_id.positive? ])
			end

			total_rows += rows.rows.length
		end
		remote.exec("COMMIT")
	rescue StandardError
		remote.exec("ROLLBACK") rescue nil
		raise
	ensure
		remote.close rescue nil
	end

	puts "Dados OK: #{ordered_tables.size} tabelas, #{total_rows} linhas."
end

def validate_remote!(config)
	remote = pg_connect(config)
	counts = %w[esocial_company_table_rows rubricas_cte_s1010_events rubricas_cte_expected_incidences esocial_certificates].to_h do |table|
		[ table, remote.exec("SELECT COUNT(*) AS count FROM #{quote_ident(remote, table)}").first["count"].to_i ]
	end
	xml_bytes = remote.exec("SELECT COALESCE(SUM(length(xml_content)), 0) AS bytes FROM esocial_company_table_rows").first["bytes"].to_i
	remote.close
	puts "Validacao: #{counts.inspect}; xml_bytes=#{xml_bytes}"
end

Timeout.timeout(900) do
	config = choose_remote_config(SUPABASE_URL)
	load_schema!(config)
	copy_data!(config)
	validate_remote!(config)
end

puts "Supabase concluido."