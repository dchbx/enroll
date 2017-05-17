module Subscribers
  class NotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\..*/]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      application_event_kinds = ApplicationEventKind.application_events_for(event_name)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

      application_event_kinds.each do |aek|
        begin
          aek.execute_notices(event_name, payload)
        rescue Exception => e
          # ADD LOGGING AND HANDLING
          puts "#{e.inspect} #{e.backtrace}"
        end
      end
    end
  end
end
