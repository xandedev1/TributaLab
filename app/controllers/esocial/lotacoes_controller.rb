module Esocial
	class LotacoesController < ApplicationController
		def index
			@snapshot = LotacoesDashboardSnapshot.new(params.permit(:q))
		end
	end
end
