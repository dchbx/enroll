module Publishers
  class Legacy::EmployerPocPendingReportPublisher
    attr_reader :gateway
    def initialize
      @gateway = TransportGateway::Gateway.new(nil, Rails.logger)
    end

    def publish(file_uri)
      process = TransportProfiles::Processes::Legacy::PushEmployerPocPendingReport.new(file_uri, @gateway)
      process.execute
    end
  end
end
