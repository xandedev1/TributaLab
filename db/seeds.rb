# Usuários do Auditor Fiscal (login)
FiscalAuditor::User.find_or_initialize_by(username: "Xande").tap do |u|
  u.password = ENV.fetch("FISCAL_AUDITOR_SEED_PASSWORD_XANDE", "123321")
  u.name = "Xande"
  u.active = true
  u.save!
end

FiscalAuditor::User.find_or_initialize_by(username: "Lobo").tap do |u|
  u.password = ENV.fetch("FISCAL_AUDITOR_SEED_PASSWORD_LOBO", "Ale180306@")
  u.name = "Lobo"
  u.active = true
  u.save!
end

# Empresas do Auditor Fiscal (multi-tenant)
load Rails.root.join("db/seeds/fiscal_companies.rb")
