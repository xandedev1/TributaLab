module RubricRecovery
	class RadarController < ApplicationController
		def show
			@snapshot = RadarSnapshot.new(radar_filters)
		end

		private

		def radar_filters
			params.permit(:tax, :confidence, :group, :conflict_pattern, :priority)
		end
	end
end