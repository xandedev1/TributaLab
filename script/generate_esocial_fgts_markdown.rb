#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "digest"
require "fileutils"
require "json"

SOURCE_PATH = ARGV.fetch(0, "tmp/esocial_fgts_2025-01.json")
OUTPUT_DIR = ARGV.fetch(1, "docs/04_referencias/esocial/fgts_2025-01")

source_path = File.expand_path(SOURCE_PATH)
output_dir = File.expand_path(OUTPUT_DIR)
data = JSON.parse(File.read(source_path, encoding: "bom|utf-8"))

source = data.fetch("source")
establishment = data.fetch("establishment")
lotations = data.fetch("lotations")

raise "Competência inesperada: #{source.fetch('period')}" unless source.fetch("period") == "01/2025"
raise "Quantidade inesperada de lotações: #{lotations.length}" unless lotations.length == 147

rows = lotations.flat_map { |lotation| lotation.fetch("rows") }
raise "Quantidade inesperada de linhas de FGTS: #{rows.length}" unless rows.length == 296

FileUtils.mkdir_p(output_dir)

markdown_path = File.join(output_dir, "cod_lotacoes_fgts_2025-01.md")
csv_path = File.join(output_dir, "cod_lotacoes_fgts_2025-01_postgresql.csv")
metadata_path = File.join(output_dir, "cod_lotacoes_fgts_2025-01_metadata.json")

def escape_cell(value)
  value.to_s.gsub("|", "\\|")
end

File.open(markdown_path, "w:UTF-8") do |file|
  file.puts "# Códigos de Lotações - FGTS - 2025/01"
  file.puts
  file.puts "- Empresa: #{establishment.fetch('name')}"
  file.puts "- CNPJ: #{establishment.fetch('registration')}"
  file.puts "- Competência: #{source.fetch('period')}"
  file.puts "- Fonte: eSocial, `Totalizador > FGTS por Empregador`"
  file.puts "- Recibo de fechamento: #{source.fetch('closing_receipt') || 'Não identificado na extração'}"
  file.puts "- Total de lotações: #{lotations.length}"
  file.puts "- Total de linhas de bases de cálculo: #{rows.length}"
  file.puts
  file.puts "## Estabelecimento #{establishment.fetch('registration')}"
  file.puts
  file.puts "| Informação | Valor |"
  file.puts "| --- | ---: |"
  file.puts "| Razão social | #{establishment.fetch('name')} |"
  file.puts "| Competência | #{source.fetch('period')} |"
  file.puts "| Lotações tipo 01 | #{lotations.count { |lotation| lotation.fetch('lotation_type_code') == '01' }} |"
  file.puts "| Lotações tipo 04 | #{lotations.count { |lotation| lotation.fetch('lotation_type_code') == '04' }} |"
  file.puts
  file.puts "## Códigos"
  file.puts

  lotations.each do |lotation|
    file.puts "#{lotation.fetch('sequence')}. `#{lotation.fetch('lotation_code')}`"
    file.puts
    file.puts "\t**Informações da lotação**"
    file.puts
    file.puts "\t| Informação | Valor |"
    file.puts "\t| --- | ---: |"
    file.puts "\t| Tipo da lotação | `#{lotation.fetch('lotation_type_code')}` |"
    file.puts "\t| Descrição do tipo da lotação | #{escape_cell(lotation.fetch('lotation_type_description'))} |"
    file.puts
    file.puts "\t**Informações sobre bases de cálculo e valores do FGTS referentes à remuneração**"
    file.puts
    file.puts "\t| Base de cálculo | Indicador de incidência | Remuneração (valor da base de cálculo) do FGTS | FGTS a ser depositado | Notificação FGTS | Natureza da rubrica |"
    file.puts "\t| --- | --- | ---: | ---: | --- | --- |"

    lotation.fetch("rows").each do |row|
      file.puts "\t| #{escape_cell(row.fetch('calculation_base'))} | #{escape_cell(row.fetch('incidence_indicator'))} | #{row.fetch('remuneration_base')} | #{row.fetch('fgts_to_deposit')} | #{escape_cell(row.fetch('fgts_notification'))} | #{escape_cell(row.fetch('rubric_nature'))} |"
    end

    file.puts
  end
end

headers = %w[
  sequence
  lotation_code
  lotation_type_code
  lotation_type_description
  calculation_base
  incidence_indicator
  remuneration_base
  fgts_to_deposit
  fgts_notification
  rubric_nature
]

CSV.open(csv_path, "w:UTF-8", force_quotes: true) do |csv|
  csv << headers
  lotations.each do |lotation|
    lotation.fetch("rows").each do |row|
      csv << [
        lotation.fetch("sequence"),
        lotation.fetch("lotation_code"),
        lotation.fetch("lotation_type_code"),
        lotation.fetch("lotation_type_description"),
        row.fetch("calculation_base"),
        row.fetch("incidence_indicator"),
        row.fetch("remuneration_base").delete_prefix("R$ ").tr(".", "").tr(",", "."),
        row.fetch("fgts_to_deposit").delete_prefix("R$ ").tr(".", "").tr(",", "."),
        row.fetch("fgts_notification"),
        row.fetch("rubric_nature")
      ]
    end
  end
end

metadata = {
  source_url: source.fetch("url"),
  extracted_at: source.fetch("extracted_at"),
  source_path: SOURCE_PATH,
  source_sha256: Digest::SHA256.file(source_path).hexdigest,
  competence: source.fetch("period"),
  establishment: establishment,
  closing_receipt: source.fetch("closing_receipt"),
  lotation_count: lotations.length,
  lotation_type_counts: lotations.group_by { |lotation| lotation.fetch("lotation_type_code") }.transform_values(&:length),
  fgts_row_count: rows.length,
  calculation_base_counts: rows.group_by { |row| row.fetch("calculation_base") }.transform_values(&:length),
  incidence_indicator_counts: rows.group_by { |row| row.fetch("incidence_indicator") }.transform_values(&:length),
  output_files: {
    markdown: markdown_path,
    postgresql_csv: csv_path,
    metadata: metadata_path
  }
}

File.write(metadata_path, JSON.pretty_generate(metadata) + "\n")

puts "Markdown: #{markdown_path}"
puts "PostgreSQL CSV: #{csv_path}"
puts "Metadata: #{metadata_path}"
puts "Lotações: #{lotations.length}"
puts "Linhas de FGTS: #{rows.length}"
