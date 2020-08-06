# frozen_string_literal: true

module Publishers
  class Legacy::OutstandingMonthlyEnrollmentsReportPublisher
    attr_reader :gateway
    def initialize
      @gateway = TransportGateway::Gateway.new(nil, Rails.logger)
    end

    def publish(file_uri)
      process = TransportProfiles::Processes::Legacy::PushOutstandingMonthlyEnrollmentsReport.new(file_uri, @gateway)
      process.execute
    end
  end
  end
