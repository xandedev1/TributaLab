module FiscalAuditor
  class CalculationDetail
    PAGE_SIZE = 100
    RECONCILIATION_METRICS = %w[
      coverage matched divergent selected_difference billing_value receivable_value
      missing_receivable missing_billing
    ].freeze

    Result = Data.define(:title, :formula, :value, :value_type, :rows, :total_rows, :components)

    attr_reader :module_name, :metric, :page

    def initialize(module_name:, metric:, params: {}, page: nil, billing_records: nil, receivable_records: nil)
      @module_name = module_name.to_s
      @metric = metric.to_s
      @params = params
      @page = [ page.to_i, 1 ].max
      @billing_records = billing_records
      @receivable_records = receivable_records
    end

    def result
      @result ||= case module_name
      when "reconciliation"
        reconciliation_result
      else
        raise ArgumentError, "Módulo de memória de cálculo inválido"
      end
    end

    def total_pages
      [ (result.total_rows.to_f / PAGE_SIZE).ceil, 1 ].max
    end

    private

    attr_reader :params

    def reconciliation_result
      raise ArgumentError, "Indicador de cruzamento inválido" unless RECONCILIATION_METRICS.include?(metric)

      dashboard = reconciliation_dashboard
      rows, title, formula, value, value_type, components = reconciliation_values(dashboard)
      Result.new(
        title: title,
        formula: formula,
        value: value,
        value_type: value_type,
        rows: paginate(rows),
        total_rows: rows.size,
        components: components
      )
    end

    def reconciliation_dashboard
      ReconciliationDashboard.new(
        billing_emission_periods: params[:billing_emission_periods],
        billing_competence_periods: params[:billing_competence_periods],
        billing_value_type: params[:billing_value_type],
        receivable_emission_periods: params[:receivable_emission_periods],
        receivable_competence_periods: params[:receivable_competence_periods],
        receivable_value_type: params[:receivable_value_type]
      ).tap do |dashboard|
        dashboard.instance_variable_set(:@all_billing_records, @billing_records) if @billing_records
        dashboard.instance_variable_set(:@all_receivable_records, @receivable_records) if @receivable_records
      end
    end

    def reconciliation_values(dashboard)
      billing_label = dashboard.billing_value_type == "gross" ? "Bruto faturado" : "Líquido faturado"
      receivable_label = dashboard.receivable_value_type == "gross" ? "Bruto lançado" : "Recebido real"
      all_entries = dashboard.entries

      case metric
      when "coverage"
        rows = all_entries.select { |entry| entry[:billing_present] && entry[:receivable_present] }
        components = [
          component("Chaves nas duas fontes", rows.size, :count),
          component("Chaves do faturamento", dashboard.billing_document_count, :count)
        ]
        [ rows, "Cobertura entre fontes", "chaves presentes nas duas fontes ÷ chaves do faturamento × 100", dashboard.match_rate, :percent, components ]
      when "matched"
        rows = all_entries.select { |entry| entry[:status] == :matched }
        [ rows, "Conciliação matemática", "quantidade de chaves cuja diferença absoluta é de até R$ 0,05", rows.size, :count, [] ]
      when "divergent"
        status_result(all_entries, :divergent, "Divergências da leitura")
      when "missing_receivable"
        status_result(all_entries, :missing_receivable, "Ausentes em recebimentos")
      when "missing_billing"
        status_result(all_entries, :missing_billing, "Ausentes em faturamento")
      when "billing_value"
        value = all_entries.sum { |entry| entry[:billing_value] }
        [ all_entries, billing_label, "soma do valor de faturamento selecionado em cada chave", value, :money, [ component(billing_label, value, :money) ] ]
      when "receivable_value"
        value = all_entries.sum { |entry| entry[:receivable_value] }
        [ all_entries, receivable_label, "soma do valor de recebimento selecionado em cada chave", value, :money, [ component(receivable_label, value, :money) ] ]
      when "selected_difference"
        billing = all_entries.sum { |entry| entry[:billing_value] }
        receivable = all_entries.sum { |entry| entry[:receivable_value] }
        components = [ component(receivable_label, receivable, :money), component(billing_label, billing, :money) ]
        [ all_entries, "Diferença selecionada", "#{receivable_label} − #{billing_label.downcase}", receivable - billing, :money, components ]
      end
    end

    def status_result(entries, status, title)
      rows = entries.select { |entry| entry[:status] == status }
      [ rows, title, "quantidade de chaves classificadas como #{title.downcase}", rows.size, :count, [] ]
    end

    def component(label, value, type)
      { label: label, value: value, type: type }
    end

    def paginate(rows)
      rows.slice((page - 1) * PAGE_SIZE, PAGE_SIZE) || []
    end
  end
end