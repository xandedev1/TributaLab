module Esocial
	class CertificatesController < ApplicationController
		def create
			certificate = CertificateImporter.call(
				file: certificate_params[:file],
				password: certificate_params[:password],
				certificate_kind: certificate_params[:certificate_kind]
			)

			redirect_to esocial_certificado_path, notice: "Certificado salvo."
		rescue ActiveRecord::RecordInvalid, ArgumentError => error
			redirect_to esocial_certificado_path, alert: error.message
		end

		def test_connection
			certificate = EsocialCertificate.find(params[:id])
			result = ConnectionTester.call(certificate: certificate)

			if result.success?
				redirect_to esocial_certificado_path, notice: "Teste eSocial OK para #{certificate.holder_label}."
			else
				redirect_to esocial_certificado_path, alert: "Teste eSocial falhou para #{certificate.holder_label}: #{result.message}"
			end
		rescue ActiveRecord::RecordNotFound, ArgumentError => error
			redirect_to esocial_certificado_path, alert: error.message
		end

		def destroy
			certificate = EsocialCertificate.find(params[:id])
			storage_path = certificate.storage_path
			certificate.destroy!
			remove_stored_file(storage_path)

			redirect_to esocial_certificado_path, notice: "Certificado excluido."
		rescue ActiveRecord::RecordNotFound => error
			redirect_to esocial_certificado_path, alert: error.message
		end

		private

		def certificate_params
			params.require(:esocial_certificate).permit(:certificate_kind, :file, :password)
		end

		def remove_stored_file(storage_path)
			certificates_dir = File.expand_path(Rails.root.join("storage", "private", "esocial", "certificates").to_s)
			file_path = File.expand_path(storage_path.to_s)
			return unless file_path.start_with?("#{certificates_dir}#{File::SEPARATOR}")
			return unless File.file?(file_path)

			File.delete(file_path)
		rescue StandardError
			nil
		end
	end
end