require "json"

module FiscalAuditor
  class ComparativoDashboard
    EFD_JSON = Rails.root.join("tmp/efd_razao.json").freeze
    RAZAO_SERVICOS_JSON = Rails.root.join("tmp/razao_servicos.json").freeze
    RAZAO_VENDAS_JSON = Rails.root.join("tmp/razao_vendas.json").freeze

    # Tabela de referência (valores da planilha enviada)
    TABELA = {
      "2022-01" => { efd: 53_282_520.82, ecf: 58_734_113.21 },
      "2022-02" => { efd: 58_986_278.11, ecf: 58_985_862.00 },
      "2022-03" => { efd: 75_800_013.97, ecf: 75_698_409.13 },
      "2022-04" => { efd: 73_164_776.72, ecf: 73_033_536.34 },
      "2022-05" => { efd: 77_076_251.39, ecf: 76_873_278.52 },
      "2022-06" => { efd: 79_067_413.67, ecf: 74_140_069.74 },
      "2022-07" => { efd: 73_756_187.16, ecf: 73_791_785.35 },
      "2022-08" => { efd: 69_237_135.92, ecf: 69_420_175.78 },
      "2022-09" => { efd: 91_168_741.92, ecf: 81_579_481.60 },
      "2022-10" => { efd: 87_528_693.76, ecf: 87_105_007.17 },
      "2022-11" => { efd: 84_452_515.24, ecf: 80_624_947.38 },
      "2022-12" => { efd: 104_390_132.38, ecf: 135_145_265.70 }
    }.freeze

    class << self
      def records(company = "solucoes")
        cache_key = "comparativo_#{company}"
        cached = instance_variable_get("@#{cache_key}")
        return cached if cached && !stale?(company, cache_key)

        data = load_records(company)
        instance_variable_set("@#{cache_key}", data)
        instance_variable_set("@#{cache_key}_sig", source_signature(company))
        data
      end

      private

      def stale?(company, cache_key)
        sig = instance_variable_get("@#{cache_key}_sig")
        !sig || sig != source_signature(company)
      end

      def source_signature(company)
        paths = [
          CompanyPath.efd_dir(company),
          CompanyPath.razao_servicos_pdf(company),
          CompanyPath.razao_vendas_pdf(company)
        ]
        paths.filter_map { |p| p.exist? ? [ p.mtime.to_i, p.size ] : nil }
      end

      def load_records(company)
        efd = load_efd
        razao_servicos = load_razao(RAZAO_SERVICOS_JSON)
        razao_vendas = load_razao(RAZAO_VENDAS_JSON)

        {
          a100: efd[:a100],
          c100: efd[:c100],
          razao_servicos: razao_servicos,
          razao_vendas: razao_vendas
        }
      end

      def load_efd
        return { a100: [], c100: [] } unless EFD_JSON.exist?

        data = JSON.parse(File.read(EFD_JSON))
        {
          a100: (data["a100"] || []).map { |r| { data_emissao: r["data_emissao"], valor: r["valor_nf"]&.to_d || 0.to_d } },
          c100: (data["c100"] || []).map { |r| { data_emissao: r["data_emissao"], valor: r["valor_nf"]&.to_d || 0.to_d } }
        }
      end

      def load_razao(json_path)
        return [] unless json_path.exist?

        data = JSON.parse(File.read(json_path))
        (data["records"] || []).map do |r|
          { data_emissao: r["data_emissao"], valor: r["credito"]&.to_d || 0.to_d }
        end
      end
    end

    attr_reader :company

    def initialize(company: "solucoes")
      @company = company
    end

    def available?
      data = self.class.records(company)
      data[:a100].any? || data[:c100].any? || data[:razao_servicos].any? || data[:razao_vendas].any?
    end

    def monthly_comparison
      data = self.class.records(company)
      
      # Our monthly totals
      our_efd = {}
      our_razao = {}
      
      (data[:a100] + data[:c100]).each do |r|
        month = r[:data_emissao]&.[](0..6)
        next unless month
        our_efd[month] = (our_efd[month] || 0.to_d) + r[:valor]
      end
      
      (data[:razao_servicos] + data[:razao_vendas]).each do |r|
        month = r[:data_emissao]&.[](0..6)
        next unless month
        our_razao[month] = (our_razao[month] || 0.to_d) + r[:valor]
      end
      
      # Build comparison
      TABELA.map do |month, tabela|
        our_efd_val = our_efd[month] || 0.to_d
        our_razao_val = our_razao[month] || 0.to_d
        
        {
          month: month,
          tabela_efd: tabela[:efd].to_d,
          nosso_efd: our_efd_val,
          diff_efd: our_efd_val - tabela[:efd].to_d,
          tabela_ecf: tabela[:ecf].to_d,
          nosso_ecf: our_razao_val,
          diff_ecf: our_razao_val - tabela[:ecf].to_d
        }
      end.sort_by { |m| m[:month] }
    end

    def totals
      monthly = monthly_comparison
      tabela_efd = monthly.sum { |m| m[:tabela_efd] }
      nosso_efd = monthly.sum { |m| m[:nosso_efd] }
      tabela_ecf = monthly.sum { |m| m[:tabela_ecf] }
      nosso_ecf = monthly.sum { |m| m[:nosso_ecf] }
      
      # Diferença da tabela (ECF - EFD) = R$ 22.707.431,37
      diff_tabela = tabela_ecf - tabela_efd
      
      # Diferença EFD (nosso - tabela) = -R$ 1.454.331,64
      diff_efd = nosso_efd - tabela_efd
      
      # Diferença ECF (nosso - tabela) = -R$ 4.031.828,87
      diff_ecf = nosso_ecf - tabela_ecf
      
      # Diferença final = diff_tabela + diff_efd + diff_ecf
      # = 22.707.431,37 + (-1.454.331,64) + (-4.031.828,87)
      # = 22.707.431,37 - 1.454.331,64 - 4.031.828,87
      # = 17.221.270,86
      diff_final = diff_tabela + diff_efd + diff_ecf
      
      {
        tabela_efd: tabela_efd,
        nosso_efd: nosso_efd,
        diff_efd: diff_efd,
        tabela_ecf: tabela_ecf,
        nosso_ecf: nosso_ecf,
        diff_ecf: diff_ecf,
        diff_tabela: diff_tabela,
        diff_nossa: diff_efd + diff_ecf,
        diff_final: diff_final
      }
    end
  end
end
