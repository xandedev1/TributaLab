module RubricasCte
	class ChainWalkController < ApplicationController
		before_action :ensure_data!

		def index
			@snapshot = ChainWalkSnapshot.new(chain_walk_filters)
		end

		private

		def ensure_data!
			Pipeline.ensure_loaded!
		end

		def chain_walk_filters
			params.permit(:q, :status, :rubric_id, :segment_id)
		end
	end
end