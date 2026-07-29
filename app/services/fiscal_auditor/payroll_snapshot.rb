require "fileutils"
require "zlib"

module FiscalAuditor
  class PayrollSnapshot
    DEFAULT_PATH = Rails.root.join("storage/private/fiscal_auditor/payroll.marshal.gz")
    FORMAT_VERSION = 1

    def initialize(source_paths, snapshot_path: DEFAULT_PATH)
      @source_paths = source_paths
      @snapshot_path = Pathname(snapshot_path)
    end

    def records
      return [] if source_paths.empty?

      (current_payload || rebuild).fetch(:records).freeze
    end

    private

    attr_reader :source_paths, :snapshot_path

    def current_payload
      return unless snapshot_path.exist?

      payload = Zlib::GzipReader.open(snapshot_path.to_s) { |gzip| Marshal.load(gzip.read) }
      payload if payload[:version] == FORMAT_VERSION && payload[:signature] == signature
    rescue TypeError, ArgumentError, Zlib::GzipFile::Error, KeyError
      nil
    end

    def rebuild
      payload = {
        version: FORMAT_VERSION,
        signature: signature,
        records: source_paths.flat_map { |path| PayrollWorkbook.new(path).records }
      }
      write_payload(payload)
      payload
    end

    def signature
      @signature ||= source_paths.map do |path|
        file = Pathname(path)
        [ file.basename.to_s, file.size, file.mtime.to_i ]
      end
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
