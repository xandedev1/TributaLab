#!/usr/bin/env ruby
# Cruzamento POR CLIENTE (tomador): faturamento (competencia 2025) x folha, por cliente.
# Reusa os parsers oficiais do app. Saida JSON para o gerador de PDF.
require "bigdecimal"; require "date"; require "json"; require "active_support/all"
root = File.expand_path("..", __dir__)
%w[payroll_workbook retention_workbook].each { |f| require File.join(root, "app/services/fiscal_auditor", f) }
base = File.join(root, "storage/private/fiscal_auditor/appa")

def norm(s) = I18n.transliterate(s.to_s).upcase.gsub(/\s+/, " ").strip
z = 0.to_d

fat = Hash.new { |h, k| h[k] = z }          # client_code -> faturamento bruto (comp 2025)
cnpjs = Hash.new { |h, k| h[k] = Hash.new(0) }
names = Hash.new { |h, k| h[k] = Hash.new(0) }
filial = Hash.new { |h, k| h[k] = Hash.new(0) }
Dir[File.join(base, "source/**/*.xlsx")].sort.each do |f|
  next unless File.basename(f).upcase.include?("RETEN")
  FiscalAuditor::RetentionWorkbook.new(f).records.each do |r|
    next unless r.client_code && r.competence&.year == 2025
    cc = r.client_code
    fat[cc] += r.billed
    cnpjs[cc][r.cnpj] += 1 if r.cnpj.present?
    names[cc][r.client.to_s.strip] += 1 if r.client.present?
    filial[cc][norm(r.filial)] += 1 if r.filial.present?
  end
end

folha = Hash.new { |h, k| h[k] = z }
fnames = Hash.new { |h, k| h[k] = Hash.new(0) }
Dir[File.join(base, "payroll/*.xlsx")].sort.each do |f|
  FiscalAuditor::PayrollWorkbook.new(f).records.each do |r|
    next unless r.event_type == "Vencimento" && r.client_code
    folha[r.client_code] += r.amount
    fnames[r.client_code][r.client.to_s.strip] += 1 if r.client.present?
  end
end

codes = (fat.keys + folha.keys).uniq
rows = codes.map do |cc|
  nm = names[cc].max_by { |_, v| v }&.first || fnames[cc].max_by { |_, v| v }&.first || ""
  fil = filial[cc].max_by { |_, v| v }&.first || ""
  {
    client_code: cc,
    cnpj: cnpjs[cc].max_by { |_, v| v }&.first || "",
    cliente: nm,
    filial: fil,
    faturamento: fat[cc].to_f.round(2),
    folha: folha[cc].to_f.round(2),
    diferenca: (fat[cc] - folha[cc]).to_f.round(2)
  }
end
rows.sort_by! { |r| -r[:faturamento] }
File.write(File.join(base, "cruzamento_cliente.json"), JSON.pretty_generate(rows: rows))

tf = rows.sum { |r| r[:faturamento] }; tp = rows.sum { |r| r[:folha] }
puts "clientes: #{rows.size} | faturamento total: #{tf.round(2)} | folha total: #{tp.round(2)}"
puts format("%-8s %-34s %14s %14s", "cod", "cliente", "faturamento", "folha")
rows.first(15).each { |r| puts format("%-8s %-34s %14.0f %14.0f", r[:client_code], r[:cliente][0, 34], r[:faturamento], r[:folha]) }
