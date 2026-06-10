#!/usr/bin/env ruby

require "optparse"
require_relative "../config/environment"

options = {
	output_dir: Rails.root.join("tmp", "lotacoes_s1020"),
	current_on: Date.today
}

parser = OptionParser.new do |opts|
	opts.banner = "Uso: ruby script/extract_s1020_lotacoes.rb [opcoes] ARQUIVO_OU_PASTA..."

	opts.on("--out DIR", "Diretorio de saida CSV/JSON") do |value|
		options[:output_dir] = Pathname.new(value)
	end

	opts.on("--as-of DATA", "Data de referencia da vigencia, ex.: 2026-06-10") do |value|
		options[:current_on] = Date.parse(value)
	end

	opts.on("-h", "--help", "Mostra esta ajuda") do
		puts opts
		exit 0
	end
end

parser.parse!

if ARGV.empty?
	warn parser
	exit 1
end

result = Esocial::LotacaoTributariaExtractor.call(
	source_paths: ARGV,
	output_dir: options[:output_dir],
	current_on: options[:current_on]
)

puts "Eventos S-1020 encontrados: #{result.rows.size}"
puts "Codigos de lotacao no quadro: #{result.current_rows.size}"
puts "Arquivos gerados:"
result.output_paths.each_value { |path| puts "- #{path}" }

if result.stats[:errors].any?
	puts "Avisos de parsing (primeiros #{result.stats[:errors].size}):"
	result.stats[:errors].each do |error|
		puts "- #{error[:source_path]} #{error[:xml_path]}: #{error[:message]}"
	end
end

if result.rows.empty?
	warn "Nenhum evento evtTabLotacao/S-1020 foi encontrado nas fontes informadas."
	exit 2
end
