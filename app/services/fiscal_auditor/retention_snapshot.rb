require "fileutils"
require "json"
require "zlib"

module FiscalAuditor
  class RetentionSnapshot
    DEFAULT_PATH = Rails.root.join("storage/private/fiscal_auditor/retentions.marshal.gz")
    LEGACY_PATH = Rails.root.join("storage/private/fiscal_auditor/retentions.json.gz")
    FORMAT_VERSION = 3
    DECIMAL_FIELDS = %w[billed inss irrf pis cofins csll iss net].freeze

    def initialize(source_paths, snapshot_path: DEFAULT_PATH)
      @source_paths = source_paths
      @snapshot_path = Pathname(snapshot_path)
    end

    def records
      return [] if source_paths.empty?

      payload = current_payload || migrate_legacy_payload || rebuild
      payload.fetch(:records).freeze
    end

    private

    attr_reader :source_paths, :snapshot_path

    def current_payload
      return unless snapshot_path.exist?

      payload = read_payload
      payload if payload[:version] == FORMAT_VERSION && payload[:signature] == signature
    rescue TypeError, ArgumentError, Zlib::GzipFile::Error, KeyError
      nil
    end

    def migrate_legacy_payload
      return unless FORMAT_VERSION == 1 && snapshot_path == DEFAULT_PATH && LEGACY_PATH.exist?

      legacy = Zlib::GzipReader.open(LEGACY_PATH.to_s) { |gzip| JSON.parse(gzip.read) }
      return unless legacy["signature"] == signature

      payload = snapshot_payload(legacy.fetch("records").map { |attributes| build_record(attributes) })
      write_payload(payload)
      payload
    rescue JSON::ParserError, Zlib::GzipFile::Error, KeyError
      nil
    end

    def rebuild
      records = source_paths.flat_map { |path| RetentionWorkbook.new(path).records }
      payload = snapshot_payload(records)
      write_payload(payload)
      payload
    end

    def snapshot_payload(records)
      { version: FORMAT_VERSION, signature: signature, records: records }
    end

    def signature
      @signature ||= source_paths.map do |path|
        file = Pathname(path)
        [ file.basename.to_s, file.size, file.mtime.to_i ]
      end
    end

    def build_record(attributes)
      values = attributes.symbolize_keys
      values[:client_code] = nil unless values.key?(:client_code)
      values[:rps] = nil unless values.key?(:rps)
      values[:invoice_number] = nil unless values.key?(:invoice_number)
      DECIMAL_FIELDS.each { |field| values[field.to_sym] = values.fetch(field.to_sym).to_d }
      values[:emission_date] = Date.iso8601(values.fetch(:emission_date))
      values[:competence] = Date.iso8601(values.fetch(:competence))
      RetentionWorkbook::Record.new(**values)
    end

    def read_payload
      Zlib::GzipReader.open(snapshot_path.to_s) { |gzip| Marshal.load(gzip.read) }
    end

    def write_payload(payload)
      FileUtils.mkdir_p(snapshot_path.dirname)
      temporary_path = snapshot_path.sub_ext(".tmp")
      Zlib::GzipWriter.open(temporary_path.to_s) { |gzip| gzip.write(Marshal.dump(payload)) }
      FileUtils.mv(temporary_path, snapshot_path)
    ensure
      FileUtils.rm_f(temporary_path) if defined?(temporary_path)
    end
  end
end
