module Esocial
	class CompanyTableRow < ApplicationRecord
		self.table_name = "esocial_company_table_rows"

		validates :event_type, :event_id, presence: true

		def self.available?
			connection.data_source_exists?(table_name)
		rescue StandardError
			false
		end

		def snapshot_attributes
			attributes_payload.to_h.merge(
				"source_path" => source_path.to_s,
				"xml_path" => xml_filename.to_s,
				"xml_content" => xml_content.to_s,
				"xml_filename" => xml_filename.to_s
			)
		end
	end
end