#!/usr/bin/env ruby

require "json"

input_path, document_path = ARGV

unless input_path && document_path
  warn "Uso: ruby script/validate_esocial_lotacoes_markdown.rb DADOS.json DOCUMENTO.md"
  exit 1
end

lotacoes = JSON.parse(File.read(input_path, encoding: "UTF-8"))
documento = File.read(document_path, encoding: "UTF-8")
blocos = documento.scan(/^(\d+)\. `([A-Z0-9-]+)`\r?\n(.*?)(?=^\d+\. `|\z)/m)

abort "Quantidade de lotações divergente" unless blocos.length == lotacoes.length

total_categorias = 0
total_bases = 0
total_adicionais = 0

lotacoes.each_with_index do |lotacao, index|
  posicao, codigo, bloco = blocos.fetch(index)

  abort "Posição divergente em #{codigo}" unless posicao.to_i == lotacao.fetch("position")
  abort "Código divergente na posição #{posicao}" unless codigo == lotacao.fetch("code")

  categorias = lotacao.fetch("categories")
  secoes = bloco.scan(/^\t\*\*(Categoria .+?)\*\*\r?\n(.*?)(?=^\t\*\*Categoria |\z)/m).to_h

  abort "Categorias divergentes em #{codigo}" unless secoes.keys == categorias.map { |categoria| categoria.fetch("name") }

  categorias.each do |categoria|
    nome = categoria.fetch("name")
    secao = secoes.fetch(nome)
    total_categorias += 1

    categoria.fetch("bases").each do |base|
      linha = "| #{base.fetch("code")} | #{base.fetch("description")} | R$ #{base.fetch("value")} |"
      abort "Base ausente em #{codigo} / #{nome}: #{base.fetch("code")}" unless secao.include?(linha)

      total_bases += 1
    end

    adicionais = categoria.fetch("additionalPositiveRows")
    linhas_adicionais = secao.lines.grep(/^\t\| Valor total do /)

    abort "Valores adicionais divergentes em #{codigo} / #{nome}" unless linhas_adicionais.length == adicionais.length

    adicionais.each do |adicional|
      valores = adicional.fetch("values").map { |valor| "R$ #{valor}" }.join(" / ")
      linha = "| #{adicional.fetch("label")} | #{valores} |"
      abort "Valor positivo ausente em #{codigo} / #{nome}: #{linha}" unless secao.include?(linha)

      total_adicionais += 1
    end
  end
end

puts "Validados: #{lotacoes.length} lotações, #{total_categorias} categorias, " \
     "#{total_bases} bases e #{total_adicionais} valores positivos adicionais."