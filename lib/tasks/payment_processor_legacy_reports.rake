namespace :reports do
  namespace :shop do
    desc "Move and run payment processor reports to the client reporting server."
    task :payment_processor_legacy_reports => :environment do
      gateway = TransportGateway::Gateway.new(nil, Rails.logger)
      process = ::TransportProfiles::Processes::Legacy::TransferPaymentProcessorReports.new(gateway)
      process.execute
    end
  end
end
