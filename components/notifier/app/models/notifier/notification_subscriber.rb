# frozen_string_literal: true

module Notifier
  class NotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\..*/]
    end

    def call(event_name, _e_start, _e_end, _msg_id, payload)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

      logger = Logger.new("#{Rails.root}/log/notification_subscriber_log_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      logger.info("NOTICE EVENT: #{event_name}---#{payload}")

      NoticeKind.where(event_name: event_name.split(".")[4]).each do |notice_kind|

        notice_kind.execute_notice(event_name, payload)
      rescue Exception => e
        logger.info("Exception: #{e}----#{event_name}----#{payload}")
        # ADD LOGGING AND HANDLING
        puts "#{e.inspect} #{e.backtrace}"
        error_payload = JSON.dump({
                                    :error => e.inspect,
                                    :message => e.message,
                                    :backtrace => e.backtrace
                                  })
        notify("acapi.error.application.enroll.remote_listener.notice_automation_responses", {
                 :resource_id => payload.first[1],
                 :event_name => event_name,
                 :return_status => "500",
                 :body => error_payload
               })

      end
    end
  end
end