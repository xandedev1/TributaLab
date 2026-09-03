#!/usr/bin/env ruby
# Agrega, por competencia 2025, os numeros do cruzamento usando os MESMOS parsers do app.
# Faturamento liquido, folha (bruta/desconto/liquida) e FGTS. Sem bootar Rails (evita bcrypt).
require "bigdecimal"
require "date"
require "json"
require "active_support/all"

root = File.expand_path("..", __dir__)
%w[payroll_workbook retention_workbook payroll_charges_workbook].each do |f|
  require File.join(root, "app/services/fiscal_auditor", f)
end

base = File.join(root, "storage/private/fiscal_auditor/appa")
MESES = { "JANEIRO" => 1, "FEVEREIRO" => 2, "MARCO" => 3, "ABRIL" => 4, "MAIO" => 5,
          "JUNHO" => 6, "JULHO" => 7, "AGOSTO" => 8, "SETEMBRO" => 9, "OUTUBRO" => 10,
          "NOVEMBRO" => 11, "DEZEMBRO" => 12 }

def z = 0.to_d
fat = Hash.new { |h, k| h[k] = z } # faturamento liquido
fat_bruto = Hash.new { |h, k| h[k] = z }
fat_ret = Hash.new { |h, k| h[k] = z }
venc = Hash.new { |h, k| h[k] = z }
desc = Hash.new { |h, k| h[k] = z }
fgts = Hash.new { |h, k| h[k] = z }
efat = Hash.new { |h, k| h[k] = z }
efat_bruto = Hash.new { |h, k| h[k] = z }
efat_ret = Hash.new { |h, k| h[k] = z }

# Faturamento em DUAS visoes:
#  (a) competencia (mes do servico) — alinha com folha; notas recentes ainda em emissao.
#  (b) emissao (arquivo do mes = faturado no mes) — base completa por mes.
Dir[File.join(base, "source/**/*.xlsx")].sort.each do |f|
  name = File.basename(f)
  next unless name.upcase.include?("RETEN")
  emkey = nil
  if name.include?("2025") || name.include?("_NOVO")
    m = MESES.find { |nm, _| I18n.transliterate(name).upcase.include?(nm) }&.last
    m ||= name[/_(\d{2})_/, 1]&.to_i
    emkey = format("2025-%02d", m) if m
  end
  FiscalAuditor::RetentionWorkbook.new(f).records.each do |r|
    comp = r.competence
    if comp&.year == 2025
      key = comp.strftime("%Y-%m")
      fat[key] += r.net; fat_bruto[key] += r.billed; fat_ret[key] += r.retained
    end
    if emkey
      efat[emkey] += r.net; efat_bruto[emkey] += r.billed; efat_ret[emkey] += r.retained
    end
  end
end

# --- Folha (Empresa 00X) ---
Dir[File.join(base, "payroll/*.xlsx")].sort.each do |f|
  FiscalAuditor::PayrollWorkbook.new(f).records.each do |r|
    key = r.competence.strftime("%Y-%m")
    if r.event_type == "Vencimento" then venc[key] += r.amount else desc[key] += r.amount end
  end
end

# --- FGTS (por lotacao, totalizador coluna Q) ---
Dir[File.join(base, "payroll_charges/*.xlsx")].sort.each do |f|
  next if File.basename(f).upcase.start_with?("INSS")
  e = FiscalAuditor::PayrollChargesWorkbook.new(f).fgts_entry
  fgts[e.period] += e.amount
end

# --- INSS empregador (INSS 2025.xlsx do app, gross - descontos segurado) ---
inss_gross = Hash.new { |h, k| h[k] = z }
inss_file = Dir[File.join(base, "payroll_charges/*.xlsx")].find { |f| File.basename(f).upcase.start_with?("INSS") }
if inss_file
  FiscalAuditor::PayrollChargesWorkbook.new(inss_file).inss_entries.each do |e|
    inss_gross[e.period] += e.amount
  end
end
disc_codes = %w[566 596 641 757]
inss_disc = Hash.new { |h, k| h[k] = z }
Dir[File.join(base, "payroll/*.xlsx")].sort.each do |f|
  FiscalAuditor::PayrollWorkbook.new(f).records.each do |r|
    next unless r.event_type == "Desconto" && disc_codes.include?(r.event_code)
    inss_disc[r.competence.strftime("%Y-%m")] += r.amount
  end
end

keys = (fat.keys + efat.keys + venc.keys + fgts.keys + inss_gross.keys).uniq.select { |k| k.start_with?("2025") }.sort
out = keys.map do |k|
  {
    competencia: k,
    faturamento_bruto: fat_bruto[k].to_f.round(2),
    faturamento_retencoes: fat_ret[k].to_f.round(2),
    faturamento_liquido: fat[k].to_f.round(2),
    emissao_bruto: efat_bruto[k].to_f.round(2),
    emissao_retencoes: efat_ret[k].to_f.round(2),
    emissao_liquido: efat[k].to_f.round(2),
    folha_vencimentos: venc[k].to_f.round(2),
    folha_descontos: desc[k].to_f.round(2),
    folha_liquida: (venc[k] - desc[k]).to_f.round(2),
    inss_empregador: inss_gross[k].to_f.round(2),
    fgts: fgts[k].to_f.round(2)
  }
end
File.write(File.join(base, "cruzamento_resultado.json"), JSON.pretty_generate(rows: out))
puts JSON.pretty_generate(rows: out)
