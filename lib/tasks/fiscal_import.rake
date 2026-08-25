namespace :fiscal do
  desc "Popula o banco relacional (fiscal_*) a partir dos parsers atuais, por empresa. Idempotente."
  task import: :environment do
    now = Time.current

    digits = ->(v) { v.to_s.gsub(/\D/, "").presence }
    month_floor = ->(d) { d ? Date.new(d.year, d.month, 1) : nil }
    to_date = lambda do |v|
      next nil if v.nil? || v == ""
      next v if v.is_a?(Date)
      next v.to_date if v.respond_to?(:to_date) && !v.is_a?(String)
      (Date.parse(v.to_s) rescue nil)
    end
    parse_period = lambda do |p|
      s = p.to_s
      s.match?(/\A\d{4}-\d{2}\z/) ? Date.new(s[0, 4].to_i, s[5, 2].to_i, 1) : nil
    end

    Fiscal::Company.order(:id).each do |company|
      slug = company.slug
      cid = company.id
      puts "== Empresa #{slug} (##{cid}) =="

      # nucleo (parsers Ruby puros) - transacional
      ActiveRecord::Base.transaction do
        # limpeza idempotente (ordem respeita FKs)
        Fiscal::LinkedAccountBalance.for_company(cid).delete_all
        Fiscal::LinkedAccount.for_company(cid).delete_all
        [ Fiscal::Billing, Fiscal::Receivable, Fiscal::Payable, Fiscal::PayrollEntry,
          Fiscal::PayrollCharge, Fiscal::EfdRecord, Fiscal::RazaoRecord, Fiscal::Devolucao ].each do |m|
          m.for_company(cid).delete_all
        end
        Fiscal::Client.for_company(cid).delete_all

        billing_recs = FiscalAuditor::Dashboard.records(slug)
        receivable_recs = FiscalAuditor::ReceivablesDashboard.records(slug)
        payroll_recs = FiscalAuditor::PayrollDashboard.records(slug)

        # clientes (unicos por codigo)
        client_names = {}
        billing_recs.each { |r| client_names[r.client_code] ||= r.client if r.client_code.present? }
        receivable_recs.each { |r| client_names[r.client_code] ||= r.client if r.client_code.present? }
        payroll_recs.each { |r| client_names[r.client_code] ||= r.client if r.client_code.present? }
        if client_names.any?
          Fiscal::Client.insert_all(client_names.map { |code, name|
            { fiscal_company_id: cid, code: code, name: name, created_at: now, updated_at: now }
          })
        end
        code_to_id = Fiscal::Client.for_company(cid).pluck(:code, :id).to_h

        billing_rows = billing_recs.map do |r|
          { fiscal_company_id: cid, fiscal_client_id: code_to_id[r.client_code],
            client_code: r.client_code, client_name: r.client, client_cnpj: digits.call(r.cnpj),
            invoice_number: r.invoice_number, rps: r.rps, status: r.status,
            issued_on: r.emission_date, competencia: month_floor.call(r.competence),
            gross_amount: r.billed, inss: r.inss, irrf: r.irrf, pis: r.pis, cofins: r.cofins,
            csll: r.csll, iss: r.iss, net_amount: r.net,
            source_file: r.source, source_row: r.source_row, created_at: now, updated_at: now }
        end
        Fiscal::Billing.insert_all(billing_rows) if billing_rows.any?

        receivable_rows = receivable_recs.map do |r|
          { fiscal_company_id: cid, fiscal_client_id: code_to_id[r.client_code],
            client_code: r.client_code, client_name: r.client, invoice_number: r.invoice_number, rps: r.rps,
            cost_center: r.cost_center, bank: r.bank, situation: r.status, reconciliation_status: r.reconciliation_status,
            issued_on: r.emission_date, competencia: month_floor.call(r.competence), payment_date: r.payment_date,
            gross_amount: r.gross, contingency: r.contingency, outstanding: r.outstanding, paid_amount: r.paid,
            source_file: r.source, source_row: r.source_row, created_at: now, updated_at: now }
        end
        Fiscal::Receivable.insert_all(receivable_rows) if receivable_rows.any?

        payroll_rows = payroll_recs.map do |r|
          { fiscal_company_id: cid, fiscal_client_id: code_to_id[r.client_code],
            employer_code: r.company, client_code: r.client_code, client_name: r.client,
            event_code: r.event_code, event_type: r.event_type, event_description: r.event_description,
            competencia: month_floor.call(r.competence), amount: r.amount,
            source_file: r.source, source_row: r.source_row, created_at: now, updated_at: now }
        end
        Fiscal::PayrollEntry.insert_all(payroll_rows) if payroll_rows.any?

        payable_rows = FiscalAuditor::ExpensesDashboard.records(slug).map do |r|
          { fiscal_company_id: cid, party: r.party, client: r.client, document: r.document,
            description: r.description, identification: r.identification, source_sheet: r.source_sheet,
            competence_expense: r.competence_expense, due_date: r.due_date, payment_date: r.payment_date,
            amount: r.amount, source_file: r.source, source_row: r.source_row, created_at: now, updated_at: now }
        end
        Fiscal::Payable.insert_all(payable_rows) if payable_rows.any?

        charge_rows = []
        FiscalAuditor::PayrollChargesDashboard.inss_entries(slug).each do |e|
          charge_rows << { fiscal_company_id: cid, kind: (e.source_column == "N" ? "inss_thirteenth" : "inss"),
            code: e.code, description: e.description, source_column: e.source_column, formula: nil,
            competencia: parse_period.call(e.period), amount: e.amount,
            source_file: e.source, source_row: e.source_row, created_at: now, updated_at: now }
        end
        FiscalAuditor::PayrollChargesDashboard.fgts_entries(slug).each do |e|
          charge_rows << { fiscal_company_id: cid, kind: (e.kind == :thirteenth ? "fgts_thirteenth" : "fgts_monthly"),
            code: nil, description: nil, source_column: e.source_column, formula: e.formula,
            competencia: parse_period.call(e.period), amount: e.amount,
            source_file: e.source, source_row: e.source_row, created_at: now, updated_at: now }
        end
        Fiscal::PayrollCharge.insert_all(charge_rows) if charge_rows.any?
      end

      # conta vinculada (extrator Python) - resiliente
      begin
        FiscalAuditor::LinkedAccountsDashboard.records(slug).each do |r|
          la = Fiscal::LinkedAccount.create!(fiscal_company_id: cid, client_code: r.codigo, client_name: r.cliente,
            uf: r.uf, contrato: r.contrato, banco: r.banco, conta: r.conta, status: r.status, obs: r.obs)
          Fiscal::LinkedAccountBalance.create!(fiscal_company_id: cid, fiscal_linked_account_id: la.id, reference: Date.new(2026, 1, 1), balance: r.saldo_jan) if r.saldo_jan
          Fiscal::LinkedAccountBalance.create!(fiscal_company_id: cid, fiscal_linked_account_id: la.id, reference: Date.new(2026, 5, 1), balance: r.saldo_mai) if r.saldo_mai
        end
      rescue => e
        puts "  [aviso] conta vinculada pulada: #{e.class}: #{e.message}"
      end

      # EFD / Razao / Devolucao (extrator Python) - resiliente
      begin
        efd = FiscalAuditor::EfdRazaoDashboard.records(slug)
        efd_rows = []
        (efd[:a100] || []).each { |r| efd_rows << { fiscal_company_id: cid, doc_type: "a100", codigo: r.codigo, num_nf: r.num_nf, issued_on: to_date.call(r.data_emissao), amount: r.valor_nf, source_file: r.source_file, page: r.page, created_at: now, updated_at: now } }
        (efd[:c100] || []).each { |r| efd_rows << { fiscal_company_id: cid, doc_type: "c100", codigo: r.codigo, num_nf: r.num_nf, issued_on: to_date.call(r.data_emissao), amount: r.valor_nf, source_file: r.source_file, page: r.page, created_at: now, updated_at: now } }
        Fiscal::EfdRecord.insert_all(efd_rows) if efd_rows.any?

        razao_rows = []
        (efd[:razao_servicos] || []).each { |r| razao_rows << { fiscal_company_id: cid, kind: "servicos", num_nf: r.num_nf, issued_on: to_date.call(r.data_emissao), credit: r.credito, source_file: r.source_file, page: r.page, created_at: now, updated_at: now } }
        (efd[:razao_vendas] || []).each { |r| razao_rows << { fiscal_company_id: cid, kind: "vendas", num_nf: r.num_nf, issued_on: to_date.call(r.data_emissao), credit: r.credito, source_file: r.source_file, page: r.page, created_at: now, updated_at: now } }
        Fiscal::RazaoRecord.insert_all(razao_rows) if razao_rows.any?

        dev_rows = FiscalAuditor::DevolucaoDashboard.new(company: slug).records.map do |r|
          { fiscal_company_id: cid, num_nf: r.num_nf, issued_on: to_date.call(r.data_emissao), amount: r.valor, source_file: r.source_file, page: r.page, created_at: now, updated_at: now }
        end
        Fiscal::Devolucao.insert_all(dev_rows) if dev_rows.any?
      rescue => e
        puts "  [aviso] efd/razao/devolucao pulada: #{e.class}: #{e.message}"
      end

      puts "   clientes=#{Fiscal::Client.for_company(cid).count} faturamento=#{Fiscal::Billing.for_company(cid).count} " \
           "receber=#{Fiscal::Receivable.for_company(cid).count} pagar=#{Fiscal::Payable.for_company(cid).count} " \
           "folha=#{Fiscal::PayrollEntry.for_company(cid).count} encargos=#{Fiscal::PayrollCharge.for_company(cid).count} " \
           "conta_vinc=#{Fiscal::LinkedAccount.for_company(cid).count} efd=#{Fiscal::EfdRecord.for_company(cid).count} " \
           "razao=#{Fiscal::RazaoRecord.for_company(cid).count} devol=#{Fiscal::Devolucao.for_company(cid).count}"
    end
    puts "IMPORT OK"
  end

  desc "Confere paridade (contagem e soma) banco x parsers, por empresa."
  task parity: :environment do
    ok = true
    Fiscal::Company.order(:id).each do |company|
      slug = company.slug
      cid = company.id
      puts "== Paridade #{slug} =="
      checks = {
        "faturamento" => [ FiscalAuditor::Dashboard.records(slug).size, Fiscal::Billing.for_company(cid).count,
                           FiscalAuditor::Dashboard.records(slug).sum { |r| r.billed }, Fiscal::Billing.for_company(cid).sum(:gross_amount) ],
        "contas_a_receber" => [ FiscalAuditor::ReceivablesDashboard.records(slug).size, Fiscal::Receivable.for_company(cid).count,
                                FiscalAuditor::ReceivablesDashboard.records(slug).sum { |r| r.gross }, Fiscal::Receivable.for_company(cid).sum(:gross_amount) ],
        "contas_a_pagar" => [ FiscalAuditor::ExpensesDashboard.records(slug).size, Fiscal::Payable.for_company(cid).count,
                              FiscalAuditor::ExpensesDashboard.records(slug).sum { |r| r.amount }, Fiscal::Payable.for_company(cid).sum(:amount) ],
        "folha" => [ FiscalAuditor::PayrollDashboard.records(slug).size, Fiscal::PayrollEntry.for_company(cid).count,
                     FiscalAuditor::PayrollDashboard.records(slug).sum { |r| r.amount }, Fiscal::PayrollEntry.for_company(cid).sum(:amount) ]
      }
      checks.each do |label, (fc, dc, fs, ds)|
        cnt = fc == dc ? "OK" : "DIVERGENTE"
        sum = (fs.to_d - ds.to_d).abs < 0.01 ? "OK" : "DIVERGENTE"
        ok = false if cnt == "DIVERGENTE" || sum == "DIVERGENTE"
        puts format("  %-18s cont: arq=%-7d db=%-7d %-10s | soma: arq=%-16.2f db=%-16.2f %s", label, fc, dc, cnt, fs, ds, sum)
      end
    end
    puts ok ? "PARIDADE 100% OK" : "HA DIVERGENCIAS"
  end
end
