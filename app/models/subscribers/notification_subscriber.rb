# frozen_string_literal: true

module Subscribers
  class NotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\..*/]
    end

    def call(event_name, _e_start, _e_end, _msg_id, payload)
      application_event_kinds = ApplicationEventKind.application_events_for(event_name)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

      application_event_kinds.each do |aek|

        aek.execute_notices(event_name, payload)
      rescue Exception => e
        # ADD LOGGING AND HANDLING
        puts "#{e.inspect} #{e.backtrace}"

      end
    end
  end
end