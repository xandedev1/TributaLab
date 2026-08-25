module FiscalAuditor
  class CalculationDetail
    PAGE_SIZE = 100
    RECONCILIATION_METRICS = %w[
      coverage matched divergent selected_difference billing_value receivable_value
      missing_receivable missing_billing
    ].freeze
    BILLING_METRICS = %w[billed retained net reconciliation cancelled].freeze
    RECEIVABLE_METRICS = %w[gross contingency paid outstanding paid_count outstanding_count].freeze
    EXPENSE_METRICS = %w[received competence non_competence paid competence_balance cash_balance].freeze
    PAYROLL_METRICS = %w[earnings discounts net billing_net difference covered deficit missing_billing].freeze

    Result = Data.define(:title, :formula, :value, :value_type, :rows, :total_rows, :components, :column_totals)

    attr_reader :module_name, :metric, :page

    def initialize(module_name:, metric:, params: {}, page: nil, billing_records: nil, receivable_records: nil, expense_records: nil, payroll_records: nil, company: "appa")
      @module_name = module_name.to_s
      @metric = metric.to_s
      @params = params
      @page = [ page.to_i, 1 ].max
      @billing_records = billing_records
      @receivable_records = receivable_records
      @expense_records = expense_records
      @payroll_records = payroll_records
      @company = company
    end

    def result
      @result ||= case module_name
      when "billing"
        billing_result
      when "receivables"
        receivables_result
      when "reconciliation"
        reconciliation_result
      when "expenses"
        expenses_result
      when "payroll"
        payroll_result
      else
        raise ArgumentError, "Módulo de memória de cálculo inválido"
      end
    end

    def total_pages
      [ (result.total_rows.to_f / PAGE_SIZE).ceil, 1 ].max
    end

    private

    attr_reader :params

    def billing_result
      raise ArgumentError, "Indicador de faturamento inválido" unless billing_metric?

      dashboard = Dashboard.new(
        emission_month: params[:emission_month],
        competence_months: params[:competence_months],
        company: @company
      )
      dashboard.instance_variable_set(:@all_records, @billing_records) if @billing_records
      records = billing_records_for(dashboard)
      title, formula, value, value_type = billing_values(dashboard, records)
      build_result(title, formula, value, value_type, records, [ component(title, value, value_type) ])
    end

    def billing_metric?
      BILLING_METRICS.include?(metric) || metric.match?(/\Atax_(?:inss|irrf|pis|cofins|csll|iss)\z/)
    end

    def billing_records_for(dashboard)
      records = dashboard.records
      records = records.select { |record| record.cnpj == params[:detail_cnpj] } if params[:detail_cnpj].present?

      case metric
      when "reconciliation"
        records.select { |record| (record.billed - record.retained - record.net).abs > 0.05 }
      when "cancelled"
        records.select { |record| I18n.transliterate(record.status).downcase.include?("cancel") }
      else
        records
      end
    end

    def billing_values(dashboard, records)
      case metric
      when "billed"
        [ "Faturado", "soma do valor faturado de cada documento", records.sum(&:billed), :money ]
      when "retained"
        [ "Total retido", "soma de INSS, IRRF, PIS, COFINS, CSLL e ISS de cada documento", records.sum(&:retained), :money ]
      when "net"
        [ "Valor líquido", "soma do valor líquido de cada documento", records.sum(&:net), :money ]
      when "reconciliation"
        [ "Divergências matemáticas", "quantidade de documentos em que faturado − retido − líquido supera R$ 0,05", records.size, :count ]
      when "cancelled"
        [ "Documentos cancelados", "quantidade de documentos cujo status indica cancelamento", records.size, :count ]
      else
        tax = metric.delete_prefix("tax_").to_sym
        [ Dashboard::TAXES.fetch(tax), "soma de #{Dashboard::TAXES.fetch(tax)} retido em cada documento", records.sum(&tax), :money ]
      end
    end

    def receivables_result
      raise ArgumentError, "Indicador de recebimentos inválido" unless RECEIVABLE_METRICS.include?(metric)

      dashboard = ReceivablesDashboard.new(
        emission_month: params[:emission_month],
        competence_months: params[:competence_months],
        company: @company
      )
      dashboard.instance_variable_set(:@all_records, @receivable_records) if @receivable_records
      records = receivable_records_for(dashboard)
      title, formula, value, value_type = receivable_values(records)
      build_result(title, formula, value, value_type, records, [ component(title, value, value_type) ])
    end

    def receivable_records_for(dashboard)
      records = dashboard.records
      records = records.select { |record| record.client_code == params[:detail_client_code] } if params[:detail_client_code].present?
      if params[:detail_category].present?
        records = records.select { |record| dashboard.send(:category, record.client) == params[:detail_category] }
      end

      case metric
      when "paid_count"
        records.select { |record| record.paid.nonzero? }
      when "outstanding_count"
        records.select { |record| record.outstanding.nonzero? }
      else
        records
      end
    end

    def receivable_values(records)
      case metric
      when "gross"
        [ "Bruto lançado", "soma do valor bruto de cada nota", records.sum(&:gross), :money ]
      when "contingency"
        [ "Contingenciado", "valor absoluto da soma do contingenciamento de cada nota", records.sum(&:contingency).abs, :money ]
      when "paid"
        [ "Recebido real", "soma do valor efetivamente recebido em cada nota", records.sum(&:paid), :money ]
      when "outstanding"
        [ "Saldo sinalizado", "soma do saldo sinalizado em cada nota", records.sum(&:outstanding), :money ]
      when "paid_count"
        [ "Notas com recebimento", "quantidade de notas com valor recebido diferente de zero", records.size, :count ]
      when "outstanding_count"
        [ "Notas com saldo", "quantidade de notas com saldo sinalizado diferente de zero", records.size, :count ]
      end
    end

    def expenses_result
      raise ArgumentError, "Indicador de despesas inválido" unless EXPENSE_METRICS.include?(metric)

      dashboard = ExpensesDashboard.new(
        periods: params[:periods],
        expense_records: @expense_records,
        receivable_records: @receivable_records,
        company: @company
      )
      rows, title, formula, value, components = expense_values(dashboard)
      build_result(title, formula, value, :money, rows, components)
    end

    def payroll_result
      raise ArgumentError, "Indicador de folha inválido" unless PAYROLL_METRICS.include?(metric)

      dashboard = PayrollDashboard.new(
        periods: params[:periods], client_code: params[:client_code],
        statuses: params[:statuses],
        payroll_records: @payroll_records, billing_records: @billing_records,
        company: @company
      )

      case metric
      when "earnings"
        payroll_event_result(dashboard, "Vencimento", "Total de vencimentos", "soma dos eventos classificados como vencimento")
      when "discounts"
        payroll_event_result(dashboard, "Desconto", "Total de descontos", "soma dos eventos classificados como desconto")
      when "net"
        rows = dashboard.records.map { |record| payroll_event_row(record) }
        build_result("Folha líquida", "vencimentos − descontos", dashboard.totals[:net], :money, rows, [
          component("Vencimentos", dashboard.totals[:earnings], :money),
          component("Descontos deduzidos", -dashboard.totals[:discounts], :money)
        ])
      when "billing_net"
        payroll_comparison_result(dashboard, "Faturamento líquido", "soma das notas não canceladas na mesma competência", :billing_net)
      when "difference"
        payroll_comparison_result(dashboard, "Margem sobre a folha", "faturamento líquido − folha líquida", :difference)
      when "covered", "deficit", "missing_billing"
        status = { "covered" => :covered, "deficit" => :deficit, "missing_billing" => :missing_billing }.fetch(metric)
        rows = dashboard.comparison_rows.select { |row| row[:status] == status }.map { |row| row.merge(row_kind: :comparison) }
        titles = { covered: "Competências cobertas", deficit: "Competências com déficit", missing_billing: "Competências sem faturamento" }
        build_result(titles.fetch(status), "quantidade de combinações cliente-mês nessa situação", rows.size, :count, rows, [])
      end
    end

    def payroll_event_result(dashboard, event_type, title, formula)
      records = dashboard.records.select { |record| record.event_type == event_type }
      value = records.sum(&:amount)
      rows = records.map { |record| payroll_event_row(record) }
      build_result(title, formula, value, :money, rows, [ component(title, value, :money) ])
    end

    def payroll_event_row(record)
      {
        row_kind: :event, record: record,
        signed_value: record.event_type == "Desconto" ? -record.amount : record.amount
      }
    end

    def payroll_comparison_result(dashboard, title, formula, field)
      rows = dashboard.comparison_rows.map { |row| row.merge(row_kind: :comparison) }
      value = rows.sum { |row| row[field] }
      build_result(title, formula, value, :money, rows, [ component(title, value, :money) ])
    end

    def expense_values(dashboard)
      received_rows = dashboard.receivable_records.map { |record| expense_receipt_row(record) }
      competence_rows = dashboard.records.select(&:competence_expense).map { |record| expense_payment_row(record) }
      non_competence_rows = dashboard.records.reject(&:competence_expense).map { |record| expense_payment_row(record) }

      case metric
      when "received"
        expense_single_value(received_rows, "Recebido real", "soma das entradas com data de recebimento no período")
      when "competence"
        expense_single_value(competence_rows, "Despesas de competência", "soma dos pagamentos classificados como competência")
      when "non_competence"
        expense_single_value(non_competence_rows, "Despesas de não competência", "soma dos pagamentos classificados como não competência")
      when "paid"
        expense_single_value(competence_rows + non_competence_rows, "Total pago no período", "despesas de competência + despesas de não competência")
      when "competence_balance"
        expense_balance(received_rows, competence_rows, "Resultado operacional", "recebido real − despesas de competência")
      when "cash_balance"
        expense_balance(received_rows, competence_rows + non_competence_rows, "Resultado de caixa", "recebido real − total pago")
      end
    end

    def expense_single_value(rows, title, formula)
      value = rows.sum { |row| row[:value] }
      [ rows, title, formula, value, [ component(title, value, :money) ] ]
    end

    def expense_balance(receipts, payments, title, formula)
      received = receipts.sum { |row| row[:value] }
      paid = payments.sum { |row| row[:value] }
      signed_payments = payments.map { |row| row.merge(signed_value: -row[:value]) }
      components = [ component("Recebido real", received, :money), component("Saídas deduzidas", -paid, :money) ]
      [ receipts + signed_payments, title, formula, received - paid, components ]
    end

    def expense_receipt_row(record)
      {
        source_kind: :receipt, date: record.payment_date, party: record.client, document: record.invoice_number,
        description: "Recebimento de nota fiscal", classification: "Entrada", source: record.source,
        source_sheet: "APPA", source_row: record.source_row, value: record.paid, signed_value: record.paid
      }
    end

    def expense_payment_row(record)
      {
        source_kind: :payment, date: record.payment_date, party: record.party, document: record.document,
        description: record.description, classification: record.identification, source: record.source,
        source_sheet: record.source_sheet, source_row: record.source_row, value: record.amount, signed_value: record.amount
      }
    end

    def build_result(title, formula, value, value_type, rows, components)
      Result.new(
        title: title,
        formula: formula,
        value: value,
        value_type: value_type,
        rows: paginate(rows),
        total_rows: rows.size,
        components: components,
        column_totals: payroll_column_totals(rows)
      )
    end

    def payroll_column_totals(rows)
      return {} unless module_name == "payroll" && rows.any?

      if rows.first[:row_kind] == :comparison
        {
          earnings: rows.sum { |row| row[:earnings] },
          discounts: rows.sum { |row| row[:discounts] },
          payroll_net: rows.sum { |row| row[:payroll_net] },
          billing_net: rows.sum { |row| row[:billing_net] },
          formula_value: rows.sum { |row| row[:difference] }
        }
      else
        {
          earnings: rows.sum { |row| row[:record].event_type == "Vencimento" ? row[:record].amount : 0.to_d },
          discounts: rows.sum { |row| row[:record].event_type == "Desconto" ? row[:record].amount : 0.to_d },
          payroll_net: nil,
          billing_net: nil,
          formula_value: rows.sum { |row| row[:signed_value] }
        }
      end
    end

    def reconciliation_result
      raise ArgumentError, "Indicador de cruzamento inválido" unless RECONCILIATION_METRICS.include?(metric)

      dashboard = reconciliation_dashboard
      rows, title, formula, value, value_type, components = reconciliation_values(dashboard)
      build_result(title, formula, value, value_type, rows, components)
    end

    def reconciliation_dashboard
      ReconciliationDashboard.new(
        billing_emission_periods: params[:billing_emission_periods],
        billing_competence_periods: params[:billing_competence_periods],
        billing_value_type: params[:billing_value_type],
        receivable_emission_periods: params[:receivable_emission_periods],
        receivable_competence_periods: params[:receivable_competence_periods],
        receivable_value_type: params[:receivable_value_type],
        company: @company
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
        rows = all_entries.select { |entry| entry[:billing_present] }
        value = rows.sum { |entry| entry[:billing_value] }
        [ rows, billing_label, "soma do valor de faturamento selecionado em cada chave", value, :money, [ component(billing_label, value, :money) ] ]
      when "receivable_value"
        rows = all_entries.select { |entry| entry[:receivable_present] }
        value = rows.sum { |entry| entry[:receivable_value] }
        [ rows, receivable_label, "soma do valor de recebimento selecionado em cada chave", value, :money, [ component(receivable_label, value, :money) ] ]
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
