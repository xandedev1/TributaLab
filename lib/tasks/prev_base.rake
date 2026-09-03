namespace :fiscal do
  desc "Base calc — Lotações unificadas: recompoe base previdenciaria (S-1200 x S-1010) e gera snapshot JSON"
  task prev_base: :environment do
    company = ENV.fetch("COMPANY", "appa")
    s1010 = ENV["S1010_DIR"] || Rails.root.join("storage/private/esocial/S1010_TODOS_OS_ANOS_APA").to_s
    eventos = ENV["EVENTOS_DIR"] || Rails.root.join("storage/private/esocial/#{company}/eventos_2025").to_s
    out = FiscalAuditor::PrevBaseDashboard.snapshot_path(company).to_s
    python = ENV["FISCAL_AUDITOR_PYTHON"].presence || "python"
    script = Rails.root.join("script/prev_base_calc.py").to_s

    cmd = [python, script, "--s1010", s1010, "--eventos", eventos, "--out", out]
    cmd += ["--mes", ENV["MES"]] if ENV["MES"].present?
    puts cmd.join(" ")
    system(*cmd) || abort("prev_base_calc.py falhou")
  end
end
