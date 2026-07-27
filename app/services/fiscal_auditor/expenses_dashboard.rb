module FiscalAuditor
  class ExpensesDashboard
    SOURCE_GLOB = Rails.root.join("storage/private/fiscal_auditor/payables/*.xlsb").to_s.freeze
    PAGE_SIZE = 100

    class << self
      def source_paths
        Dir[SOURCE_GLOB].sort
      end

      def records
        signature = source_paths.map { |path| [ path, File.mtime(path).to_i, File.size(path) ] }
        return @records if @signature == signature

        @signature = signature
        @records = ExpenseSnapshot.new(source_paths).records
      end
    end

    attr_reader :periods, :source_sheet, :identification, :page

    def initialize(periods: [], source_sheet: nil, identification: nil, page: nil, expense_records: nil, receivable_records: nil)
      @periods = normalize_periods(periods)
      @source_sheet = normalize_source(source_sheet)
      @identification = identification.to_s.strip.presence
      @page = [ page.to_i, 1 ].max
      @expense_records = expense_records
      @receivable_records = receivable_records
    end

    def available?
      all_records.any?
    end

    def available_periods
      @available_periods ||= all_records.map { |record| month_key(record.payment_date) }.uniq.sort
    end

    def available_identifications
      @available_identifications ||= records_for_period_and_source.map(&:identification).uniq.sort
    end

    def records
      @records ||= records_for_period_and_source.select do |record|
        identification.blank? || record.identification == identification
      end
    end

    def totals
      @totals ||= {
        competence: records.select(&:competence_expense).sum(&:amount),
        non_competence: records.reject(&:competence_expense).sum(&:amount),
        paid: records.sum(&:amount),
        received: received_total
      }
    end

    def competence_balance
      totals[:received] - totals[:competence]
    end

    def cash_balance
      totals[:received] - totals[:paid]
    end

    def category_breakdown
      @category_breakdown ||= records.group_by { |record| [ record.identification, record.competence_expense ] }.map do |(name, competence), category_records|
        {
          name: name,
          competence: competence,
          amount: category_records.sum(&:amount),
          payments: category_records.size
        }
      end.sort_by { |category| -category[:amount] }
    end

    def source_breakdown
      @source_breakdown ||= records.group_by(&:source_sheet).map do |source, source_records|
        {
          source: source,
          competence: source_records.select(&:competence_expense).sum(&:amount),
          non_competence: source_records.reject(&:competence_expense).sum(&:amount),
          paid: source_records.sum(&:amount),
          payments: source_records.size
        }
      end.sort_by { |source| source[:source] }
    end

    def monthly_flow
      @monthly_flow ||= records.group_by { |record| month_key(record.payment_date) }.sort.to_h.transform_values do |month_records|
        {
          competence: month_records.select(&:competence_expense).sum(&:amount),
          non_competence: month_records.reject(&:competence_expense).sum(&:amount),
          paid: month_records.sum(&:amount),
          received: received_by_month.fetch(month_key(month_records.first.payment_date), 0.to_d)
        }
      end
    end

    def top_parties(limit: 10)
      records.group_by(&:party).map do |party, party_records|
        { party: party, amount: party_records.sum(&:amount), payments: party_records.size }
      end.sort_by { |party| -party[:amount] }.first(limit)
    end

    def paginated_records
      sorted_records.slice((page - 1) * PAGE_SIZE, PAGE_SIZE) || []
    end

    def total_pages
      [ (records.size.to_f / PAGE_SIZE).ceil, 1 ].max
    end

    def source_count
      self.class.source_paths.size
    end

    private

    def all_records
      @all_records ||= @expense_records || self.class.records
    end

    def records_for_period_and_source
      @records_for_period_and_source ||= all_records.select do |record|
        period_selected?(record.payment_date) && (source_sheet.blank? || record.source_sheet == source_sheet)
      end
    end

    def sorted_records
      @sorted_records ||= records.sort_by { |record| [ record.payment_date, record.source_sheet, record.source_row ] }.reverse
    end

    def received_total
      filtered_receivables.sum(&:paid)
    end

    def received_by_month
      @received_by_month ||= filtered_receivables.group_by { |record| month_key(record.payment_date) }.transform_values { |month_records| month_records.sum(&:paid) }
    end

    def filtered_receivables
      @filtered_receivables ||= (@receivable_records || ReceivablesDashboard.records).select do |record|
        record.payment_date && period_selected?(record.payment_date)
      end
    end

    def period_selected?(date)
      periods.empty? || periods.any? do |period|
        period.length == 4 ? date.year.to_s == period : month_key(date) == period
      end
    end

    def month_key(date)
      date.strftime("%Y-%m")
    end

    def normalize_periods(values)
      Array(values).select { |period| period.to_s.match?(/\A(?:\d{4}|\d{4}-(?:0[1-9]|1[0-2]))\z/) }.map(&:to_s).uniq.sort.freeze
    end

    def normalize_source(value)
      value if %w[FUNCIONARIOS FORNECEDORES].include?(value)
    end
  end
end
