module FiscalAuditor
  class ReceivablesDashboard
    class << self
      def source_paths(company = "appa")
        Dir[CompanyPath.receivables_glob(company)].sort
      end

      def records(company = "appa")
        paths = source_paths(company)
        signature = paths.map { |path| [ path, File.mtime(path).to_i, File.size(path) ] }
        cache_key = "records_#{company}"
        return instance_variable_get("@#{cache_key}") if instance_variable_get("@#{cache_key}_sig") == signature

        records = ReceivableSnapshot.new(paths).records
        instance_variable_set("@#{cache_key}", records)
        instance_variable_set("@#{cache_key}_sig", signature)
        records
      end
    end

    attr_reader :emission_month, :company

    def initialize(emission_month: nil, competence_months: [], company: "appa")
      @emission_month = normalize_emission_month(emission_month)
      @requested_competence_months = normalize_months(competence_months)
      @company = company
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

      @available_competence_months ||= records_for_emission.filter_map { |record| month_key(record.competence) }.uniq.sort
    end

    def competence_months
      @competence_months ||= @requested_competence_months & available_competence_months
    end

    def records
      @records ||= records_for_emission.select do |record|
        competence_months.empty? || competence_months.include?(month_key(record.competence))
      end
    end

    def totals
      @totals ||= {
        gross: sum(:gross),
        contingency: sum(:contingency),
        outstanding: sum(:outstanding),
        paid: sum(:paid)
      }
    end

    def contingency_rate
      return 0.to_d if totals[:gross].zero?

      (totals[:contingency].abs / totals[:gross]) * 100
    end

    def paid_count
      records.count { |record| record.paid.nonzero? }
    end

    def outstanding_count
      records.count { |record| record.outstanding.nonzero? }
    end

    def monthly_flow
      @monthly_flow ||= records.group_by { |record| month_key(record.emission_date) }.sort.to_h.transform_values do |month_records|
        {
          gross: month_records.sum(&:gross),
          contingency: month_records.sum(&:contingency).abs,
          paid: month_records.sum(&:paid),
          outstanding: month_records.sum(&:outstanding)
        }
      end
    end

    def top_clients(limit: 10)
      grouped_clients.first(limit)
    end

    def top_contingencies(limit: 10)
      grouped_clients.sort_by { |client| -client[:contingency].abs }.first(limit)
    end

    def category_breakdown
      @category_breakdown ||= records.group_by { |record| category(record.client) }.map do |category, category_records|
        {
          category: category,
          gross: category_records.sum(&:gross),
          contingency: category_records.sum(&:contingency).abs,
          paid: category_records.sum(&:paid),
          documents: category_records.size
        }
      end.sort_by { |category| -category[:gross] }
    end

    def recent_documents(limit: 80)
      records.sort_by { |record| [ record.emission_date, record.source_row ] }.reverse.first(limit)
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
        all_records.select { |record| record.emission_date.year == 2025 }
      end
    end

    def grouped_clients
      records.group_by { |record| [ record.client_code, client_name(record.client) ] }.map do |(client_code, client), client_records|
        {
          client_code: client_code,
          client: client,
          gross: client_records.sum(&:gross),
          contingency: client_records.sum(&:contingency),
          paid: client_records.sum(&:paid),
          outstanding: client_records.sum(&:outstanding),
          documents: client_records.size
        }
      end.sort_by { |client| -client[:gross] }
    end

    def client_name(value)
      value.to_s.sub(/\A\s*\d+\s*-?\s*/, "").split("-").first.to_s.strip.presence || value
    end

    def category(value)
      normalized = I18n.transliterate(value.to_s).downcase
      return "Fornecimento" if normalized.include?("fornecimento")
      return "Mão de obra" if normalized.include?("mao de obra")
      return "Férias" if normalized.include?("ferias")
      return "Rescisões" if normalized.include?("rescis")
      return "Repactuação" if normalized.match?(/repact|reajust|reequilibr/)
      return "Diárias" if normalized.include?("diaria")

      "Outros"
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

    def normalize_emission_month(month)
      value = month.to_s
      value if value.match?(/\A2025-(?:0[1-9]|1[0-2])\z/)
    end
  end
end
