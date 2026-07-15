module Inss
  class ImportsController < ApplicationController
    def index
      @imports = PayrollImport.ordered
    end

    def new
      @imports = PayrollImport.ordered.limit(20)
    end

    def create
      files = Array(params[:files]).reject(&:blank?)
      if files.empty?
        redirect_to new_inss_import_path, alert: "Selecione ao menos um PDF."
        return
      end

      created = 0
      duplicates = 0
      failed = 0

      files.each do |file|
        bytes = file.read
        outcome = PayrollImporter.call(bytes: bytes, filename: file.original_filename)
        case outcome.status
        when :created then created += 1
        when :duplicate then duplicates += 1
        else failed += 1
        end
      end

      notice = "Importacao concluida: #{created} novo(s), #{duplicates} duplicado(s), #{failed} com erro."
      redirect_to inss_dashboard_path, notice: notice
    end

    def destroy
      import = PayrollImport.find(params[:id])
      import.destroy
      redirect_to inss_imports_path, notice: "Importacao removida."
    end
  end
end
