module Inss
  # Persiste o resultado do parser em uma transacao. Deduplica pelo hash do
  # conteudo do PDF (mesmo arquivo importado duas vezes = ignorado).
  class PayrollImporter
    Outcome = Struct.new(:import, :status, :message, keyword_init: true)

    def self.call(bytes:, filename:)
      new(bytes: bytes, filename: filename).call
    end

    def initialize(bytes:, filename:)
      @bytes = bytes
      @filename = filename
    end

    def call
      hash = PayrollPdfParser.content_hash(@bytes)
      existing = PayrollImport.find_by(content_hash: hash)
      return Outcome.new(import: existing, status: :duplicate, message: "Arquivo ja importado") if existing

      import = PayrollImport.create!(
        filename: @filename,
        content_hash: hash,
        status: "processing"
      )

      begin
        result = PayrollPdfParser.call(StringIO.new(@bytes))
        persist!(import, result)
        Outcome.new(import: import, status: :created, message: "Importado com sucesso")
      rescue => e
        import.update(status: "failed", error_message: e.message)
        Outcome.new(import: import, status: :failed, message: e.message)
      end
    end

    private

    def persist!(import, result)
      employees_count = 0
      entries_count = 0

      ApplicationRecord.transaction do
        import.update!(competencia: result.competencia, empresa: result.empresa)

        result.employees.each do |emp|
          record = import.employees.create!(
            competencia: emp.competencia,
            empresa: emp.empresa,
            orgao_codigo: emp.orgao_codigo,
            orgao_nome: emp.orgao_nome,
            contrato_codigo: emp.contrato_codigo,
            contrato_nome: emp.contrato_nome,
            matricula: emp.matricula,
            nome: emp.nome,
            cargo: emp.cargo,
            situacao_funcional: emp.situacao_funcional,
            admissao: emp.admissao,
            rescisao: emp.rescisao,
            salario: emp.salario,
            total_proventos: emp.total_proventos,
            total_descontos: emp.total_descontos,
            liquido: emp.liquido
          )
          employees_count += 1

          rows = Array(emp.entries).map do |entry|
            {
              inss_payroll_employee_id: record.id,
              bloco: entry[:bloco],
              codigo: entry[:codigo],
              historico: entry[:historico],
              referencia: entry[:referencia] || 0,
              valor: entry[:valor] || 0,
              created_at: Time.current,
              updated_at: Time.current
            }
          end
          if rows.any?
            PayrollEntry.insert_all(rows)
            entries_count += rows.size
          end
        end

        import.update!(
          status: "completed",
          employees_count: employees_count,
          entries_count: entries_count,
          imported_at: Time.current
        )
      end
    end
  end
end
