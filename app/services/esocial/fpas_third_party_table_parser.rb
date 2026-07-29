require "bigdecimal"
require "csv"
require "date"
require "digest"
require "fileutils"
require "json"

module Esocial
	class FpasThirdPartyTableParser
		SOURCE_URL = "https://frontend.esocial.gov.br/adm/Home/Index"
		SOURCE_HEADERS = %w[CODFPAS INDCOOP DtInicio DtFim CLASSTRIB CODTERC ALIQTERC].freeze
		OUTPUT_HEADERS = %w[
			fpas_code
			cooperative_indicator
			valid_from
			valid_to
			tax_classification_code
			third_party_code
			third_party_rate
		].freeze

		Row = Data.define(*OUTPUT_HEADERS.map(&:to_sym)) do
			def to_h
				FpasThirdPartyTableParser::OUTPUT_HEADERS.to_h { |header| [ header, public_send(header) ] }
			end
		end

		Result = Data.define(:rows, :output_paths, :metadata)

		def self.call(source_path:, output_dir:)
			new(source_path:, output_dir:).call
		end

		def initialize(source_path:, output_dir:)
			@source_path = Pathname.new(source_path.to_s)
			@output_dir = Pathname.new(output_dir.to_s)
		end

		def call
			rows = parse_rows
			validate_unique!(rows)
			FileUtils.mkdir_p(output_dir)

			output_paths = {
				markdown: output_dir.join("tabela_4_fpas_terceiros.md"),
				postgres_csv: output_dir.join("tabela_4_fpas_terceiros_postgresql.csv"),
				metadata: output_dir.join("tabela_4_fpas_terceiros_metadata.json")
			}
			metadata = build_metadata(rows)

			write_markdown(output_paths.fetch(:markdown), rows, metadata)
			write_postgres_csv(output_paths.fetch(:postgres_csv), rows)
			File.write(output_paths.fetch(:metadata), JSON.pretty_generate(metadata) + "\n")

			Result.new(rows:, output_paths:, metadata:)
		end

		private

		attr_reader :source_path, :output_dir

		def parse_rows
			table = CSV.read(source_path, headers: true, col_sep: "|", encoding: "bom|utf-8")
			headers = table.headers
			raise ArgumentError, "Cabeçalho inesperado: #{headers.inspect}" unless headers == SOURCE_HEADERS

			table.map.with_index(2) do |source_row, line_number|
				build_row(source_row)
			rescue ArgumentError => error
				raise ArgumentError, "Linha #{line_number}: #{error.message}", error.backtrace
			end
		end

		def build_row(source_row)
			Row.new(
				fpas_code: required_code(source_row["CODFPAS"], "CODFPAS", 3),
				cooperative_indicator: blank_to_nil(source_row["INDCOOP"]),
				valid_from: parse_date(source_row["DtInicio"], required: true),
				valid_to: parse_date(source_row["DtFim"], required: false),
				tax_classification_code: optional_code(source_row["CLASSTRIB"], "CLASSTRIB", 2),
				third_party_code: required_code(source_row["CODTERC"], "CODTERC", 4),
				third_party_rate: parse_rate(source_row["ALIQTERC"])
			)
		end

		def required_code(value, field, length)
			code = value.to_s.strip
			raise ArgumentError, "#{field} ausente" if code.empty?
			raise ArgumentError, "#{field} inválido: #{code}" unless code.match?(/\A\d{#{length}}\z/)

			code
		end

		def optional_code(value, field, length)
			code = blank_to_nil(value)
			return if code.nil?

			required_code(code, field, length)
		end

		def parse_date(value, required:)
			date = blank_to_nil(value)
			raise ArgumentError, "data obrigatória ausente" if required && date.nil?
			return if date.nil?

			Date.strptime(date, "%d%m%Y").iso8601
		rescue Date::Error
			raise ArgumentError, "data inválida: #{date}"
		end

		def parse_rate(value)
			rate = value.to_s.strip
			raise ArgumentError, "ALIQTERC ausente" if rate.empty?
			raise ArgumentError, "ALIQTERC inválida: #{rate}" unless rate.match?(/\A\d+(?:,\d+)?\z/)

			BigDecimal(rate.tr(",", ".")).to_s("F")
		end

		def blank_to_nil(value)
			value.to_s.strip.presence
		end

		def validate_unique!(rows)
			duplicates = rows.group_by(&:to_h).select { |_row, matches| matches.many? }
			raise ArgumentError, "Foram encontradas #{duplicates.size} linhas duplicadas" if duplicates.any?
		end

		def build_metadata(rows)
			{
				table: 4,
				name: "Código e Alíquotas de FPAS/Terceiros",
				source_url: SOURCE_URL,
				source_file: source_path.basename.to_s,
				source_sha256: Digest::SHA256.file(source_path).hexdigest,
				rows: rows.size,
				fpas_codes: rows.map(&:fpas_code).uniq.size,
				generated_at: Time.current.iso8601
			}
		end

		def write_postgres_csv(path, rows)
			CSV.open(path, "w", write_headers: true, headers: OUTPUT_HEADERS) do |csv|
				rows.each { |row| csv << row.to_h.values }
			end
		end

		def write_markdown(path, rows, metadata)
			lines = [
				"# Tabela 4 do eSocial - Códigos e Alíquotas de FPAS/Terceiros",
				"",
				"- Fonte: [Consulta Pública - Tabelas do eSocial](#{SOURCE_URL})",
				"- Arquivo oficial: `#{metadata.fetch(:source_file)}`",
				"- SHA-256: `#{metadata.fetch(:source_sha256)}`",
				"- Registros: #{metadata.fetch(:rows)}",
				"- Códigos FPAS: #{metadata.fetch(:fpas_codes)}",
				"",
				"## Campos",
				"",
				"| Campo oficial | Campo normalizado |",
				"| --- | --- |",
				"| CODFPAS | `fpas_code` |",
				"| INDCOOP | `cooperative_indicator` |",
				"| DtInicio | `valid_from` |",
				"| DtFim | `valid_to` |",
				"| CLASSTRIB | `tax_classification_code` |",
				"| CODTERC | `third_party_code` |",
				"| ALIQTERC | `third_party_rate` |"
			]

			rows.group_by(&:fpas_code).each do |fpas_code, fpas_rows|
				lines.concat([
					"",
					"## FPAS #{fpas_code}",
					"",
					"| INDCOOP | Início | Fim | Classificação tributária | Código de terceiros | Alíquota (%) |",
					"| --- | --- | --- | --- | --- | ---: |"
				])

				fpas_rows.each do |row|
					lines << "| #{display(row.cooperative_indicator)} | #{row.valid_from} | #{display(row.valid_to)} | #{display(row.tax_classification_code)} | `#{row.third_party_code}` | #{row.third_party_rate.tr(".", ",")} |"
				end
			end

			File.write(path, lines.join("\n") + "\n")
		end

		def display(value)
			value.presence || "—"
		end
	end
end