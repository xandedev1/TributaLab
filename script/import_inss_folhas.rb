# Importa/inspeciona folhas "RESUMO MOVIMENTO MENSAL" em massa.
#
# Uso:
#   Importar uma pasta inteira de PDFs:
#     bin/rails runner script/import_inss_folhas.rb tmp/inss_pdfs
#
#   Importar arquivos especificos:
#     bin/rails runner script/import_inss_folhas.rb caminho/a.pdf caminho/b.pdf
#
#   Inspecionar o texto extraido (para afinar o parser), sem gravar nada:
#     bin/rails runner script/import_inss_folhas.rb --inspect tmp/inss_pdfs/exemplo.pdf
#
#   Testar o parser em um arquivo, imprimindo o que seria gravado, sem gravar:
#     bin/rails runner script/import_inss_folhas.rb --dry-run tmp/inss_pdfs/exemplo.pdf

require "pdf-reader"

args = ARGV.dup
inspect = args.delete("--inspect")
dry_run = args.delete("--dry-run")

paths = args.flat_map do |arg|
  if File.directory?(arg)
    # Dir.glob trata "\" como escape no Windows; normaliza para "/".
    pattern = File.join(arg.tr("\\", "/"), "**", "*.pdf")
    Dir.glob(pattern, File::FNM_CASEFOLD)
  else
    [arg]
  end
end

if paths.empty?
  warn "Nenhum PDF informado. Passe uma pasta ou arquivos .pdf."
  exit 1
end

if inspect
  path = paths.first
  puts "== Texto extraido de #{path} =="
  reader = PDF::Reader.new(path)
  reader.pages.first(2).each_with_index do |page, idx|
    puts "\n----- Pagina #{idx + 1} -----"
    puts page.text
  end
  exit 0
end

if dry_run
  path = paths.first
  puts "== Dry-run parser: #{path} =="
  result = Inss::PayrollPdfParser.call(path)
  puts "Competencia: #{result.competencia} | Empresa: #{result.empresa}"
  puts "Funcionarios encontrados: #{result.employees.size}"
  result.employees.first(3).each do |emp|
    puts "\n#{emp.matricula} - #{emp.nome} (#{emp.situacao_funcional}) | salario #{emp.salario}"
    puts "  proventos=#{emp.total_proventos} descontos=#{emp.total_descontos} liquido=#{emp.liquido}"
    emp.entries.first(8).each do |e|
      puts "  [#{e[:bloco]}] #{e[:codigo]} #{e[:historico]} ref=#{e[:referencia]} val=#{e[:valor]}"
    end
    puts "  ... total #{emp.entries.size} lancamentos"
  end
  exit 0
end

created = duplicates = failed = 0
paths.each do |path|
  bytes = File.binread(path)
  outcome = Inss::PayrollImporter.call(bytes: bytes, filename: File.basename(path))
  case outcome.status
  when :created
    created += 1
    puts "OK      #{File.basename(path)} (#{outcome.import.employees_count} func, #{outcome.import.entries_count} lanc)"
  when :duplicate
    duplicates += 1
    puts "DUP     #{File.basename(path)}"
  else
    failed += 1
    puts "ERRO    #{File.basename(path)} -> #{outcome.message}"
  end
end

puts "\nResumo: #{created} novo(s), #{duplicates} duplicado(s), #{failed} com erro."
