module FiscalAuditor
  class Dashboard
    SOURCE_GLOB = Rails.root.join("storage/private/fiscal_auditor/source/**/*.xlsx").to_s.freeze
    TAXES = {
      inss: "INSS",
      irrf: "IRRF",
      pis: "PIS",
      cofins: "COFINS",
      csll: "CSLL",
      iss: "ISS"
    }.freeze

    class << self
      def source_paths
        Dir[SOURCE_GLOB].sort
      end

      def records
        signature = source_paths.map { |path| [ path, File.mtime(path).to_i, File.size(path) ] }
        return @records if @signature == signature

        @signature = signature
        @records = RetentionSnapshot.new(source_paths).records
      end
    end

    attr_reader :emission_month

    def initialize(emission_month: nil, competence_months: [])
      @emission_month = normalize_month(emission_month)
      @requested_competence_months = normalize_months(competence_months)
    end

    def available?
      all_records.any?
    end

    def available_emission_months
      @available_emission_months ||= all_records.filter_map { |record| month_key(record.emission_date) }
        .select { |month| month.start_with?("2025-") }
        .uniq
        .sort
    end

    def available_competence_months
      return [] unless emission_month

      @available_competence_months ||= records_for_emission
        .filter_map { |record| month_key(record.competence) }
        .uniq
        .sort
    end

    def competence_months
      @competence_months ||= @requested_competence_months & available_competence_months
    end

    def competences_by_emission
      @competences_by_emission ||= available_emission_months.to_h do |month|
        competences = all_records
          .select { |record| month_key(record.emission_date) == month }
          .filter_map { |record| month_key(record.competence) }
          .uniq
          .sort
        [ month, competences ]
      end
    end

    def records
      @records ||= records_for_emission.select do |record|
        competence_months.empty? || competence_months.include?(month_key(record.competence))
      end
    end

    def totals
      @totals ||= {
        billed: sum(:billed),
        retained: records.sum(&:retained),
        net: sum(:net)
      }
    end

    def retention_rate
      return 0.to_d if totals[:billed].zero?

      (totals[:retained] / totals[:billed]) * 100
    end

    def tax_totals
      @tax_totals ||= TAXES.transform_values.with_index do |_, index|
        sum(TAXES.keys[index])
      end
    end

    def monthly_flow
      @monthly_flow ||= records.group_by { |record| month_key(record.emission_date) }.sort.to_h.transform_values do |month_records|
        {
          billed: month_records.sum(&:billed),
          retained: month_records.sum(&:retained),
          net: month_records.sum(&:net)
        }
      end
    end

    def top_clients(limit: 8)
      records.group_by { |record| [ record.cnpj, record.client ] }.map do |(cnpj, client), client_records|
        {
          cnpj: cnpj,
          client: client,
          billed: client_records.sum(&:billed),
          retained: client_records.sum(&:retained),
          documents: client_records.size
        }
      end.sort_by { |client| -client[:billed] }.first(limit)
    end

    def recent_documents(limit: 80)
      records.sort_by { |record| [ record.emission_date || Date.new(1900), record.source_row ] }.reverse.first(limit)
    end

    def cancelled_count
      records.count { |record| I18n.transliterate(record.status).downcase.include?("cancel") }
    end

    def discrepancy_count
      records.count { |record| (record.billed - record.retained - record.net).abs > 0.05 }
    end

    def source_count
      self.class.source_paths.size
    end

    private

    def all_records
      @all_records ||= self.class.records
    end

    def records_for_emission
      @records_for_emission ||= if emission_month
        all_records.select { |record| month_key(record.emission_date) == emission_month }
      else
        all_records
      end
    end

    def sum(field)
      records.sum(&field)
    end

    def month_key(date)
      date&.strftime("%Y-%m")
    end

    def normalize_months(months)
      Array(months).select { |month| month.to_s.match?(/\A\d{4}-(?:0[1-9]|1[0-2])\z/) }.uniq.sort.freeze
    end

    def normalize_month(month)
      value = month.to_s
      value if value.match?(/\A2025-(?:0[1-9]|1[0-2])\z/)
    end
  end
end
