module FiscalAuditor
  module CompanyPath
    extend self

    def base_path(company)
      Rails.root.join("storage/private/fiscal_auditor/#{company}")
    end

    def source_glob(company)
      base_path(company).join("source/**/*.xlsx").to_s
    end

    def payables_glob(company)
      base_path(company).join("payables/*.xlsb").to_s
    end

    def receivables_glob(company)
      base_path(company).join("receivables/*.xlsb").to_s
    end

    def payroll_glob(company)
      base_path(company).join("payroll/*.xlsx").to_s
    end

    def payroll_charges_glob(company)
      base_path(company).join("payroll_charges/*.xlsx").to_s
    end

    def linked_accounts_path(company)
      base_path(company).join("linked_accounts/EXTRATO CONTA VINCULADA.xlsx")
    end

    def payables_snapshot(company)
      base_path(company).join("payables.marshal.gz")
    end

    def receivables_snapshot(company)
      base_path(company).join("receivables.marshal.gz")
    end

    def payroll_snapshot(company)
      base_path(company).join("payroll.marshal.gz")
    end

    def retentions_snapshot(company)
      base_path(company).join("retentions.marshal.gz")
    end

    def retentions_legacy(company)
      base_path(company).join("retentions.json.gz")
    end
  end
end
