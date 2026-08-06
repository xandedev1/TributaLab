module FiscalAuditor
  class UploadController < BaseController
    skip_before_action :require_fiscal_auditor, only: %i[create]
    skip_before_action :verify_authenticity_token, only: %i[create]

    def create
      uploaded_file = params[:file]
      
      if uploaded_file.blank?
        render json: { error: "No file provided" }, status: :bad_request
        return
      end

      target_path = Rails.root.join("storage/private/fiscal_auditor.zip")
      
      File.binwrite(target_path, uploaded_file.read)
      
      render json: { 
        status: "ok", 
        path: target_path.to_s,
        size: File.size(target_path)
      }
    end
  end
end
