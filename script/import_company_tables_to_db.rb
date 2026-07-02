#!/usr/bin/env ruby

require_relative "../config/environment"

unless Esocial::CompanyTableRow.available?
	abort "Tabela esocial_company_table_rows ausente. Rode bundle exec rails db:migrate antes."
end

def xml_content_for(row)
	path = Pathname.new(row.source_path.to_s)
	return nil unless path.file? && path.extname.casecmp(".xml").zero?

	File.binread(path).force_encoding(Encoding::UTF_8).scrub
end

def xml_filename_for(row)
	path = Pathname.new(row.source_path.to_s)
	return path.basename.to_s if path.file?

	row.xml_path.presence || "#{row.event_id}.xml"
end

def import_rows(event_type, rows)
	rows.each do |row|
		attributes_payload = row.to_h.stringify_keys.except("xml_content", "xml_filename")
		Esocial::CompanyTableRow.create!(
			event_type: event_type,
			event_id: row.event_id,
			attributes_payload: attributes_payload,
			xml_content: xml_content_for(row),
			xml_filename: xml_filename_for(row),
			source_path: row.source_path.to_s
		)
	end
end

ActiveRecord::Base.transaction do
	Esocial::CompanyTableRow.where(event_type: %w[s1005 s1020]).delete_all

	import_rows("s1005", Esocial::EstabelecimentosObrasDashboardSnapshot.new.rows)
	import_rows("s1020", Esocial::LotacoesDashboardSnapshot.new.rows)
end

puts "S-1005 importados: #{Esocial::CompanyTableRow.where(event_type: 's1005').count}"
puts "S-1020 importados: #{Esocial::CompanyTableRow.where(event_type: 's1020').count}"