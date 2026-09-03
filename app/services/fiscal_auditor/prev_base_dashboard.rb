module FiscalAuditor
  # Le o snapshot gerado por script/prev_base_calc.py e agrega por lotacao/competencia.
  class PrevBaseDashboard
    Row = Struct.new(:lotacao, :competencia, :categoria, :base_inss, :patronal, :rat_fap, :terceiros, :total_prev, keyword_init: true)

    def self.snapshot_path(company)
      CompanyPath.base_path(company).join("prev_base_calc.json")
    end

    def initialize(company)
      @company = company
      @payload = load_payload
    end

    def available?
      @payload.present? && rows.any?
    end

    def generated_at
      @payload && @payload["generated_at"]
    end

    def rates
      @payload&.dig("rates") || {}
    end

    def totais
      @payload&.dig("totais") || {}
    end

    def rows
      @rows ||= Array(@payload && @payload["rows"]).map do |r|
        Row.new(
          lotacao: r["lotacao"], competencia: r["competencia"], categoria: r["categoria"],
          base_inss: r["base_inss"].to_f, patronal: r["patronal"].to_f, rat_fap: r["rat_fap"].to_f,
          terceiros: r["terceiros"].to_f, total_prev: r["total_prev"].to_f
        )
      end
    end

    def competencias
      rows.map(&:competencia).uniq.sort
    end

    # Agrupado por lotacao, com o total consolidado e a lista de competencias.
    def por_lotacao
      rows.group_by(&:lotacao).map do |lotacao, list|
        {
          lotacao: lotacao,
          base_inss: list.sum(&:base_inss),
          patronal: list.sum(&:patronal),
          rat_fap: list.sum(&:rat_fap),
          terceiros: list.sum(&:terceiros),
          total_prev: list.sum(&:total_prev),
          competencias: list.map(&:competencia).uniq.size
        }
      end.sort_by { |h| -h[:total_prev] }
    end

    private

    def load_payload
      path = self.class.snapshot_path(@company)
      return nil unless File.exist?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError
      nil
    end
  end
end
