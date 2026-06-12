module Esocial
	class CompanyAuthorizationsController < ApplicationController
		def create
			certificate = EsocialCertificate.find(authorization_params[:esocial_certificate_id])
			certificate.esocial_company_authorizations.create!(
				authorization_params.except(:esocial_certificate_id).merge(
					status: "declared",
					verification_method: "manual"
				)
			)

			redirect_to esocial_certificado_path, notice: "Procuracao informada."
		rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
			redirect_to esocial_certificado_path, alert: error.message
		end

		def destroy
			EsocialCompanyAuthorization.find(params[:id]).destroy!
			redirect_to esocial_certificado_path, notice: "Procuracao removida."
		end

		private

		def authorization_params
			params.require(:esocial_company_authorization).permit(:esocial_certificate_id, :target_company_cnpj, :target_company_name, :notes)
		end
	end
end