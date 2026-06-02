class LegalBasisController < ApplicationController
	def index
		@workbook = BaseLegal::RecoveryCreditWorkbook.new
		@sheets = @workbook.sheets
		@sheet = @workbook.sheet(params[:sheet])
		@summary_sheet = @workbook.sheet("Resumo")
		@fullscreen = params[:fullscreen] == "1"
	end
end