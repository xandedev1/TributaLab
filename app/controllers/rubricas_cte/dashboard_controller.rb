module RubricasCte
	class DashboardController < ApplicationController
		before_action :ensure_data!

		def index
			redirect_to rubricas_cte_root_path(q: dashboard_filters[:q], status: dashboard_filters[:status])
		end

		private

		def ensure_data!
			Pipeline.ensure_loaded!
		end

		def dashboard_filters
			params.permit(:q, :status)
		end
	end
end