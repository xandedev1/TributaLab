require "open3"

module FiscalAuditor
  class LinkedAccountsDashboard
    Record = Data.define(
      :codigo,
      :uf,
      :cliente,
      :contrato,
      :banco,
      :conta,
      :saldo_jan,
      :saldo_mai,
      :status,
      :obs
    )

    SOURCE_PATH = Rails.root.join("storage/private/fiscal_auditor/linked_accounts/EXTRATO CONTA VINCULADA.xlsx").freeze
    EXTRACTOR_PATH = Rails.root.join("script/extract_linked_accounts.py").freeze
    JSON_PATH = Rails.root.join("tmp/extrato_conta_vinculada.json").freeze

    class << self
      def records(company = "appa")
        cache_key = "records_#{company}"
        return instance_variable_get("@#{cache_key}") if instance_variable_get("@#{cache_key}") && !stale?(company)

        run_extractor(company) if stale?(company)
        instance_variable_set("@#{cache_key}", load_records(company))
        instance_variable_set("@#{cache_key}_mtime", source_mtime(company))
        instance_variable_get("@#{cache_key}")
      end

      private

      def stale?(company)
        cache_key = "records_#{company}"
        !instance_variable_get("@#{cache_key}") || instance_variable_get("@#{cache_key}_mtime") != source_mtime(company)
      end

      def source_mtime(company)
        path = CompanyPath.linked_accounts_path(company)
        path.exist? ? path.mtime.to_i : nil
      end

      def run_extractor(company)
        python = ENV.fetch("PYTHON", Rails.root.join(".venv/Scripts/python.exe").to_s)
        source = CompanyPath.linked_accounts_path(company)
        system(python, EXTRACTOR_PATH.to_s, source.to_s, exception: true)
      end

      def load_records(company)
        return [] unless JSON_PATH.exist?

        JSON.parse(File.read(JSON_PATH)).map do |row|
          next if row["codigo"].to_s.start_with?("TOTAL")

          Record.new(
            codigo: row["codigo"],
            uf: row["uf"],
            cliente: row["cliente"],
            contrato: row["contrato"],
            banco: row["banco"],
            conta: row["conta"],
            saldo_jan: row["saldo_jan"]&.to_d || 0.to_d,
            saldo_mai: row["saldo_mai"]&.to_d || 0.to_d,
            status: row["status"],
            obs: row["obs"]
          )
        end.compact
      end
    end

    def records
      self.class.records(company)
    end

    def available?
      records.any?
    end

    def total_records
      records.size
    end

    attr_reader :company

    def initialize(company: "appa")
      @company = company
    end

    def active_records
      records.select { |r| r.status&.match?(/ATIVO/i) }
    end

    def closed_records
      records.select { |r| r.status&.match?(/ENCERRADO/i) }
    end

    def active_count
      active_records.size
    end

    def closed_count
      closed_records.size
    end

    def total_saldo_jan
      records.sum(&:saldo_jan)
    end

    def total_saldo_mai
      records.sum(&:saldo_mai)
    end

    def closed_with_balance
      closed_records.select { |r| r.saldo_mai.positive? }
    end

    def closed_with_balance_count
      closed_with_balance.size
    end

    def closed_with_balance_total
      closed_with_balance.sum(&:saldo_mai)
    end

    def without_account
      records.select { |r| r.conta.blank? }
    end

    def without_account_count
      without_account.size
    end

    def with_account_count
      records.count { |r| r.conta.present? }
    end

    def top_by_balance(limit: 10)
      records.sort_by { |r| -r.saldo_mai }.first(limit)
    end

    def top_clients(limit: 10)
      records.group_by(&:cliente).map do |cliente, rows|
        {
          cliente: cliente,
          codigo: rows.first.codigo,
          total: rows.sum(&:saldo_mai),
          count: rows.size
        }
      end.sort_by { |h| -h[:total] }.first(limit)
    end

    def status_breakdown
      records.group_by { |r| r.status.to_s.split(" - ").first.presence || "SEM STATUS" }.map do |status, rows|
        {
          status: status,
          count: rows.size,
          total: rows.sum(&:saldo_mai)
        }
      end.sort_by { |h| -h[:total] }
    end

    def uf_breakdown
      records.group_by(&:uf).map do |uf, rows|
        {
          uf: uf || "—",
          count: rows.size,
          total: rows.sum(&:saldo_mai)
        }
      end.sort_by { |h| -h[:total] }
    end
  end
end
