module Esocial
	class SyncController < ApplicationController
		def index
			@snapshot = SyncDashboardSnapshot.new
		end
	end
end