require_relative "../config/environment"
require "json"

# 1. Rubricas usadas na folha de set/2025 (codigo + historico)
conn = ActiveRecord::Base.connection
comps = conn.select_values("SELECT DISTINCT competencia FROM inss_payroll_employees ORDER BY competencia")
sep = comps.grep(/09/).last
abort "sem setembro" unless sep

rows = conn.select_rows(<<~SQL)
  SELECT DISTINCT e.codigo, e.historico
  FROM inss_payroll_entries e
  JOIN inss_payroll_employees emp ON emp.id = e.inss_payroll_employee_id
  WHERE emp.competencia = #{conn.quote(sep)}
  ORDER BY e.codigo
SQL

folha = rows.map { |codigo, historico| { "codigo" => codigo.to_s.strip, "historico" => historico.to_s.strip } }
puts "Folha #{sep}: #{folha.size} codigos"

# 2. Tabela do portal (descricao + incidencia CP)
portal = JSON.parse(File.read("storage/private/esocial/appa/rubricas_portal_2026-07-31.json"))
# Vigentes: sem fimValid ou fimValid futuro; pega a mais recente por descricao+natureza
vig = portal.select { |r| r["fimValid"] == "-" }
by_desc = vig.group_by { |r| [r["descricao"].to_s.upcase.strip, r["natureza"].to_s] }
              .transform_values { |rs| rs.max_by { |r| r["recepcao"].to_s } }

# 3. Cruzamento por descricao normalizada
norm = ->(s) { s.to_s.upcase.gsub(/[^A-Z0-9 ]/, "").gsub(/\s+/, " ").strip }
portal_by_norm = vig.group_by { |r| norm.call(r["descricao"]) }
                     .transform_values { |rs| rs.max_by { |r| r["recepcao"].to_s } }

cruzado = folha.map do |f|
  p = portal_by_norm[norm.call(f["historico"])]
  f.merge(
    "portal_descricao" => p&.dig("descricao"),
    "natureza" => p&.dig("natureza"),
    "incCP" => p&.dig("incCP"),
    "incIR" => p&.dig("incIR"),
    "incFGTS" => p&.dig("incFGTS"),
    "idRubrica" => p&.dig("idRubrica"),
    "matched" => !p.nil?
  )
end

matched = cruzado.select { |c| c["matched"] }
base_patronal = matched.select { |c| c["incCP"] == "11" }
ja_suspensas = matched.select { |c| c["incCP"] == "95" }

puts "Cruzadas: #{matched.size}/#{folha.size}"
puts "Com incidencia CP=11 (base patronal): #{base_patronal.size}"
puts "Com incidencia CP=95 (ja suspensas): #{ja_suspensas.size}"

File.write("tmp/cruzamento_rubricas_set2025.json", JSON.pretty_generate(cruzado))

puts "\n=== BASE PATRONAL (incCP=11) — candidatas ao vinculo jun/2026 ==="
base_patronal.each { |c| puts "  #{c['codigo']} | #{c['historico'][0, 50]} | nat #{c['natureza']}" }

puts "\n=== NAO CRUZADAS (verificar) ==="
cruzado.reject { |c| c["matched"] }.each { |c| puts "  #{c['codigo']} | #{c['historico'][0, 60]}" }
