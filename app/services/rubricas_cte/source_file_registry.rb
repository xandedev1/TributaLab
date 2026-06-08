require "digest"

module RubricasCte
	class SourceFileRegistry
		def self.find_or_create!(kind:, repo_path:, original_path: nil, notes: nil)
			new(kind:, repo_path:, original_path:, notes:).find_or_create!
		end

		def initialize(kind:, repo_path:, original_path: nil, notes: nil)
			@kind = kind
			@repo_path = repo_path
			@original_path = original_path
			@notes = notes
		end

		def find_or_create!
			path = Rails.root.join(repo_path)
			raise ArgumentError, "Fonte local nao encontrada: #{repo_path}" unless path.exist?

			source_file = SourceFile.find_or_initialize_by(sha256: Digest::SHA256.file(path).hexdigest.upcase)
			source_file.update!(
				kind: kind,
				original_path: original_path,
				repo_path: repo_path,
				file_size: path.size,
				notes: notes
			)
			source_file
		end

		private

		attr_reader :kind, :repo_path, :original_path, :notes
	end
end