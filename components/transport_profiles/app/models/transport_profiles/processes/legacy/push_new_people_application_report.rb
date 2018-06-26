module TransportProfiles
  class Processes::Legacy::PushNewPeopleApplicationReport < Processes::Process
    def initialize(report_file_name, gateway)
      super("Distribute system generated legacy new person applications report", gateway)
      @report_file_name = report_file_name

      add_step(TransportProfiles::Steps::RouteTo.new(:aca_shop_analytics_archive, report_file_name, gateway))
      add_step(TransportProfiles::Steps::RouteTo.new(:aca_shop_analytics_outbound, report_file_name, gateway))
      add_step(TransportProfiles::Steps::DeleteFile.new(report_file_name, gateway))
    end

    def self.used_endpoints
      [
        :aca_shop_analytics_archive,
        :aca_shop_analytics_outbound
      ]
    end
  end
end
