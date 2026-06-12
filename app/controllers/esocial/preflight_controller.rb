module Esocial
	class PreflightController < ApplicationController
		def index
			@snapshot = PreflightDashboardSnapshot.new
			@certificate = EsocialCertificate.new
			@authorization = EsocialCompanyAuthorization.new
		end
	end
end