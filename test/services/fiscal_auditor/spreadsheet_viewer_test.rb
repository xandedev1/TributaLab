require "test_helper"

module FiscalAuditor
  class SpreadsheetViewerTest < ActiveSupport::TestCase
    test "reads a complete xlsx row window with Excel coordinates" do
      path = Dashboard.source_paths.first
      result = SpreadsheetViewer.new(source_kind: "billing", filename: File.basename(path), row: 10).result

      assert_equal "Planilha1", result.sheet
      assert_equal 1, result.page
      assert_equal [ "A", "B", "C" ], result.columns.first(3)
      assert_equal result.total_columns, result.columns.size
      assert result.rows.any? { |row| row["number"] == 10 }
    end

    test "reads the APPA worksheet from xlsb and selects the focused page" do
      path = ReceivablesDashboard.source_paths.first
      result = SpreadsheetViewer.new(
        source_kind: "receivables", filename: File.basename(path), row: 103
      ).result

      assert_equal "APPA", result.sheet
      assert_equal 2, result.page
      assert_equal 101, result.rows.first.fetch("number")
      assert result.rows.any? { |row| row["number"] == 103 }
    end

    test "rejects files and worksheets outside the authorized source" do
      assert_raises(ArgumentError) do
        SpreadsheetViewer.new(source_kind: "billing", filename: "database.yml").result
      end

      path = Dashboard.source_paths.first
      assert_raises(ArgumentError) do
        SpreadsheetViewer.new(
          source_kind: "billing", filename: File.basename(path), sheet: "Aba inexistente"
        ).result
      end
    end
  end
end
