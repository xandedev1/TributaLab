#!/usr/bin/env ruby

require_relative "../config/environment"

source_path = ARGV.fetch(0, Rails.root.join("docs/04_referencias/esocial/tabela_4/TABELA4_v1_Conteudo.csv"))
output_dir = ARGV.fetch(1, Rails.root.join("docs/04_referencias/esocial/tabela_4"))
result = Esocial::FpasThirdPartyTableParser.call(source_path:, output_dir:)

puts "Tabela 4 processada: #{result.rows.size} registros"
result.output_paths.each { |name, path| puts "#{name}: #{path}" }