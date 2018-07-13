module Publishers
  class Legacy::EmployeeTerminationReportPublisher
    attr_reader :gateway
    def initialize
      @gateway = TransportGateway::Gateway.new(nil, Rails.logger)
    end

    def publish(file_uri)
      process = TransportProfiles::Processes::Legacy::PushEmployeeTerminationsReport.new(file_uri, @gateway)
      process.execute
    end
  end
end
