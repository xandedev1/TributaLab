require "openssl"

module Esocial
	class OpenSslLegacyProvider
		def self.load
			return unless defined?(OpenSSL::Provider)
			return if @loaded

			load_provider("default")
			load_provider("legacy")
			@loaded = true
		end

		def self.load_provider(name)
			OpenSSL::Provider.load(name)
		rescue OpenSSL::OpenSSLError, NotImplementedError
			nil
		end
		private_class_method :load_provider
	end
end
