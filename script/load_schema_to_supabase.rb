#!/usr/bin/env ruby

require "active_record"

url = ENV["SUPABASE_DATABASE_URL"].to_s
abort "Defina SUPABASE_DATABASE_URL no terminal antes de rodar." if url.empty?

schema_path = File.expand_path("../db/schema.rb", __dir__)
schema_source = File.read(schema_path)

# Supabase owns these schemas/extensions; application tables are enough here.
schema_source = schema_source.lines.reject do |line|
	line.match?(/^\s*(create_schema|enable_extension)\b/)
end.join

ActiveRecord::Base.establish_connection(url)
ActiveRecord::Schema.verbose = true

eval(schema_source, TOPLEVEL_BINDING, schema_path)

connection = ActiveRecord::Base.connection
connection.create_table(:schema_migrations, id: false, if_not_exists: true) do |table|
	table.string :version, null: false
end

unless connection.indexes(:schema_migrations).any? { |index| index.columns == [ "version" ] }
	connection.add_index :schema_migrations, :version, unique: true, name: "unique_schema_migrations"
end

connection.execute("TRUNCATE schema_migrations")
versions = Dir.glob(File.expand_path("../db/migrate/*.rb", __dir__)).map do |path|
	File.basename(path).split("_").first
end.sort

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

puts "Schema carregado no Supabase. Migrations marcadas: #{versions.size}."