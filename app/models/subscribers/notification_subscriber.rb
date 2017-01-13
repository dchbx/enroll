module Subscribers
  class NotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
     [/acapi\.info\.events\..*/]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      application_event_kinds = ApplicationEventKind.application_events_for(event_name)
      Rails.logger.info("NOTICE EVENT: #{event_name} #{payload}")
      application_event_kinds.each do |aek|
        begin
          Rails.logger.info("strating to execute_notices")
          aek.execute_notices(event_name, payload)
          Rails.logger.info("execute_notices finished")
        rescue => e
          Rails.logger.info("Failed to execute_notices #{e} #{e.backtrace}")
        end
      end
    end

    def self.subscribe
      Rails.logger.info "notification_subscriber initialized"
      super
    end
  end
end