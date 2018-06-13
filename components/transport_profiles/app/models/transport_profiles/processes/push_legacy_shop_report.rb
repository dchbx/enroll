module TransportProfiles
  class Processes::PushLegacyShopReport < Processes::Process
    def initialize(report_file_name, gateway)
      super("Distribute system generated employee terminations report", gateway)
      @report_file_name = report_file_name

      add_step(TransportProfiles::Steps::RouteTo.new(:shop_legacy_report_archive, report_file_name, gateway))
      add_step(TransportProfiles::Steps::RouteTo.new(:shop_legacy_report_client_destination, report_file_name, gateway))
      add_step(TransportProfiles::Steps::DeleteFile.new(report_file_name, gateway))
    end

    def self.used_endpoints
      [
        :shop_legacy_report_archive,
        :shop_legacy_report_client_destination
      ]
    end
  end
end
