#!/usr/bin/env ruby

require "json"

def positive_money?(value)
  Float(value.delete(".").tr(",", "."), exception: false).to_f.positive?
end

input_path, output_path = ARGV

unless input_path && output_path
  warn "Uso: ruby script/generate_esocial_lotacoes_markdown.rb DADOS.json DOCUMENTO.md"
  exit 1
end

lotacoes = JSON.parse(File.read(input_path, encoding: "UTF-8"))
documento = File.read(output_path, encoding: "UTF-8")
cabecalho, separator, = documento.partition(/^## Códigos\s*$/)

abort "Seção '## Códigos' não encontrada em #{output_path}" if separator.empty?
abort "A extração deve conter uma lista de lotações" unless lotacoes.is_a?(Array) && lotacoes.any?

lotacoes.each_with_index do |lotacao, index|
  posicao = index + 1
  codigo = lotacao.fetch("code")
  categorias = lotacao.fetch("categories")

  abort "Posição inválida para #{codigo}" unless lotacao.fetch("position") == posicao
  abort "Código de lotação inválido: #{codigo}" unless codigo.match?(/\AE\d{5}-\d{3}-\d{2}A\z/)
  abort "FPAS ausente em #{codigo}" if lotacao.fetch("fpas").empty?
  abort "Código de terceiros ausente em #{codigo}" if lotacao.fetch("thirdPartyCode").empty?
  abort "Código de terceiros suspenso ausente em #{codigo}" if lotacao.fetch("suspendedThirdPartyCode").empty?
  abort "Categoria ausente em #{codigo}" unless categorias.is_a?(Array) && categorias.any?

  categorias.each do |categoria|
    bases = categoria.fetch("bases")
    codigos = bases.map { |base| base.fetch("code") }
    valores_adicionais = categoria.fetch("additionalPositiveRows")

    abort "Bases inválidas em #{codigo} / #{categoria.fetch("name")}" unless codigos == %w[11 12 13 14]

    valores_adicionais.each do |valor|
      valores = valor.fetch("values")
      contexto = "#{codigo} / #{categoria.fetch("name")}"

      abort "Descrição de valor adicional ausente em #{contexto}" if valor.fetch("label").empty?
      abort "Valor adicional ausente em #{contexto}" if valores.empty?
      abort "Valor adicional não positivo em #{contexto}" unless valores.all? { |item| positive_money?(item) }
    end
  end
end

linhas = [cabecalho.rstrip, "", "## Códigos", ""]

lotacoes.each do |lotacao|
  linhas << "#{lotacao.fetch("position")}. `#{lotacao.fetch("code")}`"
  linhas << ""
  linhas << "\t**Informações da lotação**"
  linhas << ""
  linhas << "\t| Informação | Valor |"
  linhas << "\t| --- | ---: |"
  linhas << "\t| FPAS | `#{lotacao.fetch("fpas")}` |"
  linhas << "\t| Código de terceiros | `#{lotacao.fetch("thirdPartyCode")}` |"
  linhas << "\t| Código de terceiros com recolhimento suspenso | `#{lotacao.fetch("suspendedThirdPartyCode")}` |"

  lotacao.fetch("categories").each do |categoria|
    linhas << ""
    linhas << "\t**#{categoria.fetch("name")}**"
    linhas << ""
    linhas << "\t| Código | Base de cálculo | Valor |"
    linhas << "\t| ---: | --- | ---: |"

    categoria.fetch("bases").each do |base|
      linhas << "\t| #{base.fetch("code")} | #{base.fetch("description")} | R$ #{base.fetch("value")} |"
    end

    valores_adicionais = categoria.fetch("additionalPositiveRows")
    next if valores_adicionais.empty?

    linhas << ""
    linhas << "\t**Outros valores positivos da categoria**"
    linhas << ""
    linhas << "\t| Informação | Valor |"
    linhas << "\t| --- | ---: |"

    valores_adicionais.each do |valor|
      valores = valor.fetch("values").map { |item| "R$ #{item}" }.join(" / ")
      linhas << "\t| #{valor.fetch("label")} | #{valores} |"
    end
  end

  linhas << ""
end

File.write(output_path, "#{linhas.join("\n").rstrip}\n", encoding: "UTF-8")