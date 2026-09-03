#!/usr/bin/env ruby
# Isola os dados da BAHIA reusando os parsers oficiais do app (valores batem com o total).
# Geografia = coluna Filial do faturamento (ex.: "027 - SALVADOR"). Mapeia cliente->UF e
# classifica faturamento e folha. INSS/FGTS da Bahia sao rateados pela folha da Bahia.
require "bigdecimal"; require "date"; require "json"; require "active_support/all"
root = File.expand_path("..", __dir__)
%w[payroll_workbook retention_workbook].each { |f| require File.join(root, "app/services/fiscal_auditor", f) }
base = File.join(root, "storage/private/fiscal_auditor/appa")

MESES = { "JANEIRO" => 1, "FEVEREIRO" => 2, "MARCO" => 3, "ABRIL" => 4, "MAIO" => 5, "JUNHO" => 6,
          "JULHO" => 7, "AGOSTO" => 8, "SETEMBRO" => 9, "OUTUBRO" => 10, "NOVEMBRO" => 11, "DEZEMBRO" => 12 }
BA_TOKENS = ["SALVADOR", "CAMACARI", "FEIRA DE SANTANA", "VITORIA DA CONQUISTA", "ITABUNA", "ILHEUS",
             "JUAZEIRO", "BARREIRAS", "JEQUIE", "ALAGOINHAS", "TEIXEIRA DE FREITAS", "LAURO DE FREITAS",
             "SIMOES FILHO", "PORTO SEGURO", "EUNAPOLIS", "PAULO AFONSO"]

def norm(s) = I18n.transliterate(s.to_s).upcase.gsub(/\s+/, " ").strip
def city?(f) = norm(f).gsub(%r{[\d/\.\-]}, "").match?(/[A-Z]{3,}/)
def ba?(f)
  n = norm(f)
  return false if n.empty?
  return true if n.match?(/\A0?27\b/) || n.start_with?("027 ")
  BA_TOKENS.any? { |t| n.include?(t) }
end
def emonth(name)
  n = norm(name)
  m = MESES.find { |k, _| n.include?(k) }&.last
  m || name[/_(\d{2})_/, 1]&.to_i
end

z = 0.to_d
# Passo 1: cliente -> filial dominante (formato cidade) + coleta registros de faturamento
client_filial = Hash.new { |h, k| h[k] = Hash.new(0) }
fat_recs = []
Dir[File.join(base, "source/**/*.xlsx")].sort.each do |f|
  name = File.basename(f)
  next unless name.upcase.include?("RETEN")
  FiscalAuditor::RetentionWorkbook.new(f).records.each do |r|
    client_filial[r.client_code][norm(r.filial)] += 1 if r.client_code && city?(r.filial)
    # COMPETENCIA (mes de referencia do servico), so 2025
    comp = r.competence
    fat_recs << [r.client_code, norm(r.filial), comp.strftime("%Y-%m"), r.billed, r.retained] if comp&.year == 2025
  end
end
client_ba = {}
client_filial.each { |cc, cnt| client_ba[cc] = ba?(cnt.max_by { |_, v| v }.first) }
row_ba = ->(cc, fil) { client_ba.key?(cc) ? client_ba[cc] : ba?(fil) }

fat_ba = Hash.new { |h, k| h[k] = [z, z] }
fat_tot = Hash.new { |h, k| h[k] = [z, z] }
fat_recs.each do |cc, fil, key, billed, ret|
  fat_tot[key][0] += billed; fat_tot[key][1] += ret
  if row_ba.call(cc, fil)
    fat_ba[key][0] += billed; fat_ba[key][1] += ret
  end
end

# Passo 2: folha por cliente/mes, classifica BA
folha_ba = Hash.new { |h, k| h[k] = z }
folha_tot = Hash.new { |h, k| h[k] = z }
Dir[File.join(base, "payroll/*.xlsx")].sort.each do |f|
  FiscalAuditor::PayrollWorkbook.new(f).records.each do |r|
    next unless r.event_type == "Vencimento"
    key = r.competence.strftime("%Y-%m")
    folha_tot[key] += r.amount
    folha_ba[key] += r.amount if client_ba[r.client_code]
  end
end

# Passo 3: INSS/FGTS Bahia rateados pela folha
tot = JSON.parse(File.read(File.join(base, "cruzamento_resultado.json")))["rows"].to_h { |r| [r["competencia"], r] }
rows = tot.keys.sort.map do |k|
  ratio = folha_tot[k].positive? ? (folha_ba[k] / folha_tot[k]) : 0.to_d
  {
    competencia: k,
    faturamento_bruto: fat_ba[k][0].to_f.round(2),
    faturamento_retencoes: fat_ba[k][1].to_f.round(2),
    faturamento_liquido: (fat_ba[k][0] - fat_ba[k][1]).to_f.round(2),
    folha_vencimentos: folha_ba[k].to_f.round(2),
    inss_empregador: (tot[k]["inss_empregador"].to_d * ratio).to_f.round(2),
    fgts: (tot[k]["fgts"].to_d * ratio).to_f.round(2),
    rateio_folha_pct: (ratio * 100).to_f.round(2)
  }
end
File.write(File.join(base, "cruzamento_bahia.json"), JSON.pretty_generate(rows: rows))

# diagnostico
nba = client_ba.count { |_, v| v }
tfb = rows.sum { |r| r[:faturamento_bruto] }; tfat = fat_tot.values.sum { |v| v[0] }.to_f
tfo = folha_ba.values.sum(&:to_f); tfot = folha_tot.values.sum(&:to_f)
puts "clientes BA: #{nba} de #{client_ba.size}"
puts format("Faturamento BA (competencia): %.0f de %.0f = %.1f%%", tfb, tfat, tfb / tfat * 100)
puts format("Folha BA: %.0f de %.0f = %.1f%%", tfo, tfot, tfo / tfot * 100)
puts format("%-8s %13s %13s %12s %11s %7s", "comp", "fat.BA", "folha.BA", "INSS.BA", "FGTS.BA", "rateio")
rows.each { |r| puts format("%-8s %13.0f %13.0f %12.0f %11.0f %6.1f%%", r[:competencia], r[:faturamento_bruto], r[:folha_vencimentos], r[:inss_empregador], r[:fgts], r[:rateio_folha_pct]) }
