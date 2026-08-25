# Empresas do Auditor Fiscal (multi-tenant). Idempotente: pode rodar quantas vezes quiser.
# Uso: ruby bin/rails runner "load Rails.root.join('db/seeds/fiscal_companies.rb')"
Fiscal::Company.find_or_create_by!(slug: "appa") do |c|
  c.legal_name = "APPA Servicos Temporarios e Efetivos LTDA"
  c.trade_name = "APPA Facilities"
  c.cnpj       = "05969071000110"
end

Fiscal::Company.find_or_create_by!(slug: "solucoes") do |c|
  c.legal_name = "SOLUCOES SERVICOS TERCEIRIZADOS LTDA."
  c.trade_name = "Solucoes"
  c.cnpj       = "09445502000109"
end
