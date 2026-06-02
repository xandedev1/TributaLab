require "test_helper"

module RubricRecovery
	class RadarSnapshotTest < ActiveSupport::TestCase
		test "loads all rows from arquivo enquadrado" do
			snapshot = RadarSnapshot.new

			assert_equal 464, snapshot.total_events
			assert_equal 247, snapshot.divergent_records.size
			assert_equal 224, snapshot.metrics.find { |metric| metric[:label] == "Alta/media" }[:value]
			assert_equal 140, snapshot.metrics.find { |metric| metric[:label] == "CP/INSS" }[:value]
			assert_equal 245, snapshot.metrics.find { |metric| metric[:label] == "IRRF" }[:value]
			assert_equal 126, snapshot.metrics.find { |metric| metric[:label] == "FGTS" }[:value]
		end

		test "calculates confidence and conflict distributions from workbook" do
			snapshot = RadarSnapshot.new

			confidence = snapshot.confidence_distribution.index_by { |item| item[:key] }
			patterns = snapshot.conflict_patterns.index_by { |item| item[:key] }

			assert_equal 297, confidence["ALTA"][:value]
			assert_equal 106, confidence["MEDIA"][:value]
			assert_equal 37, confidence["BAIXA"][:value]
			assert_equal 24, confidence["MUITO_BAIXA"][:value]
			assert_equal 120, patterns["CP+IRRF+FGTS"][:value]
			assert_equal 101, patterns["IRRF"][:value]
			assert_equal 20, patterns["CP+IRRF"][:value]
			assert_equal 4, patterns["IRRF+FGTS"][:value]
			assert_equal 2, patterns["FGTS"][:value]
			assert_equal 0, patterns["CP"][:value]
		end

		test "filters navigable imported records" do
			snapshot = RadarSnapshot.new({ tax: "fgts", confidence: "MEDIA" })

			assert_equal 13, snapshot.rubrics.size
			assert_includes snapshot.rubrics.map { |rubric| rubric[:code] }, "1600"
		end
	end
end