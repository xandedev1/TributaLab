#!/usr/bin/env ruby

require "pg"

url = ENV["SUPABASE_DATABASE_URL"].to_s
abort "Defina SUPABASE_DATABASE_URL no terminal antes de rodar." if url.empty?

begin
	connection = PG.connect(url)
	row = connection.exec(<<~SQL).first
		SELECT
			current_user,
			current_database(),
			inet_server_addr()::text AS server_addr,
			inet_server_port()::text AS server_port
	SQL

	puts "Conexao Supabase OK: user=#{row['current_user']} db=#{row['current_database']} server=#{row['server_addr']}:#{row['server_port']}"
	connection.close
rescue PG::ConnectionBad => error
	message = error.message
	if message.include?("password authentication failed")
		warn "Falha de autenticacao no Supabase. Confira a senha do banco no painel do Supabase ou gere uma nova em Project Settings > Database."
		warn "Se a senha tiver caracteres como @, #, %, :, /, ? ou &, use a URI pronta do painel ou codifique esses caracteres na URL."
	elsif message.include?("could not translate host name")
		warn "Host do Supabase nao encontrado. A URL precisa estar completa e nao pode conter '...'."
	else
		warn "Nao consegui conectar no Supabase: #{message.lines.first&.strip}"
	end
	exit 1
end