require "fileutils"
require "open3"

module Esocial
	class WindowsCertificateBundle
		BUNDLE_PATH = Rails.root.join("storage", "private", "esocial", "windows-ca-bundle.pem")
		MAX_AGE = 7.days

		def self.path
			new.path
		end

		def path
			return unless Gem.win_platform?
			return BUNDLE_PATH.to_s if fresh_bundle?

			generate_bundle
			BUNDLE_PATH.to_s if File.file?(BUNDLE_PATH)
		end

		private

		def fresh_bundle?
			File.file?(BUNDLE_PATH) && File.mtime(BUNDLE_PATH) > MAX_AGE.ago
		end

		def generate_bundle
			FileUtils.mkdir_p(BUNDLE_PATH.dirname)
			stdout, status = Open3.capture2("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", powershell_script)
			return unless status.success? && stdout.include?("-----BEGIN CERTIFICATE-----")

			File.binwrite(BUNDLE_PATH, stdout)
		rescue StandardError
			nil
		end

		def powershell_script
			<<~POWERSHELL
				$stores = @('Cert:\\CurrentUser\\Root', 'Cert:\\LocalMachine\\Root', 'Cert:\\CurrentUser\\CA', 'Cert:\\LocalMachine\\CA')
				foreach ($store in $stores) {
				  Get-ChildItem -Path $store -ErrorAction SilentlyContinue | Where-Object { $_.RawData } | ForEach-Object {
				    '-----BEGIN CERTIFICATE-----'
				    [Convert]::ToBase64String($_.RawData, 'InsertLineBreaks')
				    '-----END CERTIFICATE-----'
				  }
				}
			POWERSHELL
		end
	end
end
