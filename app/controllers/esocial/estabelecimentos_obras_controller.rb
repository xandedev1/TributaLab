module Esocial
	class EstabelecimentosObrasController < ApplicationController
		def index
			@snapshot = EstabelecimentosObrasDashboardSnapshot.new(params.permit(:q))
		end
	end
end
