module RubricasCte
	class Pipeline
		def self.ensure_loaded!
			new.ensure_loaded!
		end

		def self.refresh!
			new.refresh!
		end

		def ensure_loaded!
			return if CatalogRubric.exists? && S1010TimelineSegment.exists? && RubricIdentityLink.exists? && Finding.exists?

			refresh!
		end

		def refresh!
			NaturezaEsocialImporter.call
			s1010_source = S1010ZipImporter.call
			TimelineBuilder.call(source_file: s1010_source)
			IdentityMatcher.call
			AuditEngine.call
		end
	end
end