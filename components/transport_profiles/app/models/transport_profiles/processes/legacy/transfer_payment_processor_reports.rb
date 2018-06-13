module TransportProfiles
  class Processes::Legacy::TransferPaymentProcessorReports < Processes::Process

    def initialize(gateway)
      super("Distribute legacy reports from payment processors", gateway)

      list_existing_files_step = TransportProfiles::Steps::ListEntries.new(:aca_legacy_report_extracts, :existing_report_files, gateway)
      find_new_files_step = TransportProfiles::Steps::ListEntries.new(:payment_processor_legacy_reports, :new_report_files, gateway) do |entries, p_context|
        new_file_threshold = Time.now - 2.hours
        recent_entries = entries.select { |ent| ent.mtime >= new_file_threshold.to_i }
        existing_file_names = p_context.get(:existing_report_files).map { |entry| File.basename(entry.path) }
        recent_entries.reject { |ne| existing_file_names.include?(File.basename(ne.uri.path)) }
      end
      add_step(list_existing_files_step)
      add_step(find_new_files_step)
      add_step(TransportProfiles::Steps::RouteTo.new(:aca_legacy_report_extracts_archive, :new_report_files, gateway, source_credentials: :payment_processor_legacy_reports))
      add_step(TransportProfiles::Steps::RouteTo.new(:aca_legacy_report_extracts, :new_report_files, gateway, source_credentials: :payment_processor_legacy_reports))
    end

    def self.used_endpoints
      [
        :aca_legacy_report_extracts_archive,
        :aca_legacy_report_extracts,
        :payment_processor_legacy_reports
      ]
    end

  end
end
