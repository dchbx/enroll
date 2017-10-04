module Subscribers
  class ShopInitialEmployerQuietPeriodEnded < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.employer.initial_employer_quiet_period_ended"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      effective_on_string = nil

      begin
        stringed_key_payload = payload.stringify_keys
        effective_on_string = stringed_key_payload["effective_on"]
        effective_on = effective_on_string.blank? ? nil : (Date.strptime(effective_on_string, "%Y-%m-%d") rescue nil)

        query_results = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ["coverage_selected"])
        query_results.each do |hbx_enrollment_id|
          notify("acapi.info.events.hbx_enrollment.coverage_selected", {
            :hbx_enrollment_id => hbx_enrollment_id,
            :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#initial",
            :reply_to => "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"
            })
        end

        termination_results = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ["coverage_terminated", "coverage_canceled", "coverage_termination_pending"])
        termination_results.each do |termed_enrollment_id|
          notify("acapi.info.events.hbx_enrollment.terminated", {
            :hbx_enrollment_id => termed_enrollment_id,
            :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
            :reply_to => "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"
          })
        end
        
      rescue Exception => e
        error_payload = JSON.dump({
          :error => e.inspect,
          :message => e.message,
          :backtrace => e.backtrace
          })
        notify("acapi.error.events.employer.initial_employer_quiet_period_ended.unknown_error", {
          :effective_on => effective_on_string,
          :return_status => "500",
          :body => error_payload
        })
      end
    end
  end
end
