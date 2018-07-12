module Publishers
  class Legacy::ShopBrokersReportPublisher
    attr_reader :gateway
    def initialize
      @gateway = TransportGateway::Gateway.new(nil, Rails.logger)
    end

    def publish(file_uri)
      process = TransportProfiles::Processes::Legacy::PushShopBrokersReport.new(file_uri, @gateway)
      process.execute
    end
  end
end
