#!/usr/bin/env ruby

require "json"
require "pg"
require_relative "../config/environment"

SUPABASE_URL = ENV["SUPABASE_DATABASE_URL"].to_s
abort "Defina SUPABASE_DATABASE_URL no terminal antes de rodar." if SUPABASE_URL.empty?

EXCLUDED_TABLES = %w[
	schema_migrations
	ar_internal_metadata
	esocial_certificates
].freeze

local = ActiveRecord::Base.connection
remote = PG.connect(SUPABASE_URL)

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

tables = local.tables.reject { |table| EXCLUDED_TABLES.include?(table) || table.start_with?("solid_") }.sort
ordered_tables = table_order(local, tables)
quoted_tables = tables.map { |table| quote_ident(remote, table) }.join(", ")

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

		puts "#{table}: #{rows.rows.length} linhas"
	end
remote.exec("COMMIT")
rescue StandardError
	remote.exec("ROLLBACK") rescue nil
	raise
end

puts "Migração de dados concluída. Tabelas copiadas: #{ordered_tables.size}."