#!/usr/bin/env ruby
# frozen_string_literal: true

require "nokogiri"
require "csv"
require "json"
require "fileutils"
require "digest"

SOURCE_URL = "https://suporte.quarta.com.br/LayOuts/eSocial/Tabelas/Tabela_04.htm"
SOURCE_HTML_PATH = "tmp/quarta_tabela_04.html"
OUTPUT_DIR = "docs/04_referencias/esocial/tabela_4_quarta"

FileUtils.mkdir_p(OUTPUT_DIR)

html = File.read(SOURCE_HTML_PATH, encoding: "UTF-8")
doc = Nokogiri::HTML(html)
table = doc.at_css("table")
rows = table.css("tbody > tr")

def normalize_description(html)
  html.gsub(/<br\s*\/?>/i, " ")
      .gsub(/<[^>]+>/, "")
      .gsub(/\s+/, " ")
      .strip
end

def split_codes(code_text)
  lines = code_text.split("\n").map(&:strip).reject(&:empty?)
  codes = []
  lines.each do |line|
    if line.match?(/\A\d{4}\z/)
      codes << line
    else
      # Concatenated 4-digit codes, e.g. "000100020003"
      line.scan(/\d{4}/).each { |c| codes << c }
    end
  end
  codes
end

def split_rates(rate_text)
  rate_text.scan(/\d+(?:[,.]\d+)?%/).map(&:strip)
end

def split_names(name_text, codes)
  code_name_map = {
    "0000" => "ISENTO / NÃO APLICÁVEL",
    "0001" => "SALÁRIO EDUCAÇÃO",
    "0002" => "INCRA",
    "0003" => "TOTAL",
    "0004" => "SENAI",
    "0008" => "SESI",
    "0016" => "SENAC",
    "0032" => "SESC",
    "0064" => "SEBRAE",
    "0128" => "DPC",
    "0256" => "FUNDO AEROVIÁRIO",
    "0512" => "PREVIDÊNCIA SOCIAL",
    "1024" => "SEST",
    "2048" => "SENAT",
    "3072" => "TOTAL",
    "3139" => "TOTAL",
    "4096" => "SESCOOP",
    "4099" => "TOTAL",
    "4163" => "TOTAL"
  }

  # Some HTML rows concatenate "TOTAL" without a + separator
  normalized = name_text
               .gsub(/([A-Za-z\*])(TOTAL)\b/, '\1+ \2')
               .gsub(/TOTAL\b/, '+ TOTAL')
               .strip
  names = normalized.split(/[+\n]/).map(&:strip).reject(&:empty?)

  if names.length == codes.length
    return names
  elsif names.length < codes.length
    # Pad missing names using known code map
    padded = []
    name_idx = 0
    codes.each do |code|
      if name_idx < names.length && names[name_idx].match?(/#{Regexp.escape(code_name_map[code] || '')}/i)
        padded << names[name_idx]
        name_idx += 1
      elsif code_name_map[code]
        padded << code_name_map[code]
      else
        padded << (name_idx < names.length ? names[name_idx] : "TERCEIRO")
        name_idx += 1 if name_idx < names.length
      end
    end
    return padded if padded.length == codes.length
  end

  # Fallback: map all codes to known names
  mapped = codes.map { |code| code_name_map[code] }
  return mapped if mapped.all?

  # Last resort: repeat raw text
  [name_text.strip]
end

def process_detail_row(cells, current_fpas, current_description, current_regime, records)
  return if cells.nil? || cells.empty?

  texts = cells.map { |c| c.text.strip }

  # Convention rows have a cell with "Com convênio" or "Sem convênio"
  convention_idx = texts.index { |t| t.match?(/Com convênio|Sem convênio/i) }

  if convention_idx
    other_indices = (0...cells.length).to_a - [convention_idx]

    # Prefer a cell with a single 4-digit total code; otherwise use the one with most codes
    total_code_idx = other_indices.find { |i| cells[i].text.strip.match?(/\A\d{4}\z/) }
    code_idx = total_code_idx || other_indices.max_by { |i| split_codes(cells[i].text).length }

    rate_idx = other_indices.max_by { |i| split_rates(cells[i].text).length }

    return unless code_idx && rate_idx

    records << {
      fpas_code: current_fpas,
      fpas_description: current_description,
      regime: current_regime,
      calculation_base: "Remuneração dos Segurados",
      third_party_name: "COMBINAÇÃO",
      third_party_code: split_codes(cells[code_idx].text).first,
      third_party_rate: split_rates(cells[rate_idx].text).first,
      convention_situation: texts[convention_idx]
    }
    return
  end

  # Identify base cell
  base_idx = texts.index { |t| t.match?(/Remuneração|Receita bruta|Salário\s*de\s*Contribuição/i) }
  base = base_idx ? texts[base_idx] : ""

  remaining_indices = base_idx ? ((0...cells.length).to_a - [base_idx]) : (0...cells.length).to_a

  # Score remaining cells by number of 4-digit codes and rate patterns
  code_idx = remaining_indices.select { |i| split_codes(cells[i].text).length > 0 }
                              .max_by { |i| split_codes(cells[i].text).length }

  rate_idx = remaining_indices.select { |i| split_rates(cells[i].text).length > 0 }
                              .max_by { |i| split_rates(cells[i].text).length }

  return unless code_idx && rate_idx

  codes = split_codes(cells[code_idx].text)
  rates = split_rates(cells[rate_idx].text)

  # Name cell
  name_idx = (remaining_indices - [code_idx, rate_idx]).find do |i|
    texts[i].match?(/SALÁRIO|INCRA|SENAI|SESI|SENAC|SESC|SEBRAE|SESCOOP|SEST|SENAT|DPC|FUNDO|PREVIDÊNCIA|TOTAL|SEST\+SENAT/i)
  end

  # Single code 0000 with zero rate means no third-party contribution applies
  if codes == ["0000"] && rates.any? { |r| r.gsub(",", ".").to_f.zero? }
    records << {
      fpas_code: current_fpas,
      fpas_description: current_description,
      regime: current_regime,
      calculation_base: base.gsub(/\s+/, " "),
      third_party_name: "NÃO APLICÁVEL",
      third_party_code: "0000",
      third_party_rate: rates.first,
      convention_situation: nil
    }
    return
  end

  return if name_idx.nil?

  names = split_names(cells[name_idx].text, codes)

  min_len = [names.length, codes.length, rates.length].min
  return if min_len.zero?

  min_len.times do |i|
    records << {
      fpas_code: current_fpas,
      fpas_description: current_description,
      regime: current_regime,
      calculation_base: base.gsub(/\s+/, " "),
      third_party_name: names[i],
      third_party_code: codes[i],
      third_party_rate: rates[i],
      convention_situation: nil
    }
  end
end

# Track state across rows
records = []
current_fpas = nil
current_description = nil
current_regime = nil

rows.each do |tr|
  cells = tr.css("td")
  next if cells.empty?

  first_text = cells[0].text.strip
  is_fpas_header = first_text.match?(/\A\d{3}\z/)
  is_regime_header = first_text.match?(/\A(EMPRESAS|COOPERATIVAS|PESSOA JURÍDICA E AGROINDÚSTRIA)\z/i)

  # Section header rows (EMPRESAS/COOPERATIVAS/etc.) inside an FPAS block
  if is_regime_header
    current_regime = first_text.upcase
    next
  end

  # FPAS header row
  if is_fpas_header
    current_fpas = first_text
    current_description = cells[1] ? normalize_description(cells[1].inner_html) : nil

    if cells.length == 3
      # Multi-row block: third cell is the regime header
      current_regime = cells[2].text.strip.upcase
      next
    else
      # Single-row block: remaining cells contain the detail data
      # Default regime is EMPRESAS unless already set differently by a prior header in the same block
      current_regime = "EMPRESAS"
      detail_cells = cells[2..-1]
      process_detail_row(detail_cells, current_fpas, current_description, current_regime, records)
      next
    end
  end

  # Skip note/blank rows
  next if cells.length == 1 && first_text.empty?
  next if first_text.start_with?("*Havendo recolhimento", "Notas:")

  # Subheader inside convention note blocks
  if first_text.match?(/Situação do Contribuinte|Combinação dos Códigos/i)
    next
  end

  # Detail row inside current FPAS block
  process_detail_row(cells, current_fpas, current_description, current_regime, records)
end

# Deduplicate preserving order
seen = {}
unique_records = records.reject do |r|
  key = r.values_at(:fpas_code, :regime, :third_party_code, :third_party_rate, :convention_situation)
  if seen[key]
    true
  else
    seen[key] = true
    false
  end
end

# Build markdown
md_path = File.join(OUTPUT_DIR, "tabela_4_quarta_fpas_terceiros.md")
csv_path = File.join(OUTPUT_DIR, "tabela_4_quarta_fpas_terceiros.csv")
postgres_csv_path = File.join(OUTPUT_DIR, "tabela_4_quarta_fpas_terceiros_postgresql.csv")
metadata_path = File.join(OUTPUT_DIR, "tabela_4_quarta_fpas_terceiros_metadata.json")

File.open(md_path, "w:UTF-8") do |f|
  f.puts "# Códigos e Alíquotas de FPAS/Terceiros"
  f.puts ""
  f.puts "Fonte: [Quarta RH - Tabela 04](#{SOURCE_URL})"
  f.puts ""
  f.puts "Resumo: #{unique_records.length} registros extraídos."
  f.puts ""

  unique_records.group_by { |r| r[:fpas_code] }.each do |fpas, fpas_records|
    desc = fpas_records.first[:fpas_description]
    f.puts "## FPAS #{fpas}"
    f.puts ""
    f.puts "**Atividades:** #{desc}"
    f.puts ""
    f.puts "| Regime | Base de Cálculo | Terceiro | Código | Alíquota | Situação/Convênio |"
    f.puts "|--------|-----------------|----------|--------|----------|-------------------|"
    fpas_records.each do |r|
      f.puts "| #{r[:regime]} | #{r[:calculation_base]} | #{r[:third_party_name]} | #{r[:third_party_code]} | #{r[:third_party_rate]} | #{r[:convention_situation] || '-'} |"
    end
    f.puts ""
  end
end

# Build normalized CSV
csv_headers = %w[fpas_code fpas_description regime calculation_base third_party_name third_party_code third_party_rate convention_situation]
CSV.open(csv_path, "w:UTF-8", write_headers: true, headers: csv_headers) do |csv|
  unique_records.each { |r| csv << csv_headers.map { |h| r[h.to_sym] } }
end

# PostgreSQL CSV uses comma with quoted strings and dot decimal
CSV.open(postgres_csv_path, "w:UTF-8", col_sep: ",", quote_char: '"', force_quotes: true) do |csv|
  csv << csv_headers
  unique_records.each do |r|
    rate = r[:third_party_rate].to_s.gsub("%", "").gsub(",", ".").strip
    rate = nil if rate.empty?
    csv << [
      r[:fpas_code],
      r[:fpas_description],
      r[:regime],
      r[:calculation_base],
      r[:third_party_name],
      r[:third_party_code],
      rate,
      r[:convention_situation]
    ]
  end
end

metadata = {
  source_url: SOURCE_URL,
  source_html_path: SOURCE_HTML_PATH,
  downloaded_at: Time.now.iso8601,
  source_sha256: Digest::SHA256.hexdigest(html),
  record_count: unique_records.length,
  fpas_count: unique_records.map { |r| r[:fpas_code] }.uniq.length,
  output_files: {
    markdown: md_path,
    csv: csv_path,
    postgresql_csv: postgres_csv_path,
    metadata: metadata_path
  }
}

File.write(metadata_path, JSON.pretty_generate(metadata) + "\n")

puts "Registros: #{unique_records.length}"
puts "FPAS distintos: #{metadata[:fpas_count]}"
puts "Arquivos gerados em #{OUTPUT_DIR}:"
puts "  #{md_path}"
puts "  #{csv_path}"
puts "  #{postgres_csv_path}"
puts "  #{metadata_path}"
