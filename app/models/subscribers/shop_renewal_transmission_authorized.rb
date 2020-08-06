# frozen_string_literal: true

module Subscribers
  class ShopRenewalTransmissionAuthorized < ::Acapi::Subscription
    include Acapi::Notifiers
    def self.subscription_details
      ["acapi.info.events.employer.renewal_transmission_authorized"]
    end

    def call(_event_name, _e_start, _e_end, _msg_id, payload)
      employer_fein = nil
      employer_id = nil
      effective_on_string = nil
      begin
        stringed_key_payload = payload.stringify_keys
        employer_id = stringed_key_payload["employer_id"]
        employer_fein = stringed_key_payload["fein"]
        effective_on_string = stringed_key_payload["effective_on"]
        effective_on = effective_on_string.blank? ? nil : (begin
                                                             Date.strptime(effective_on_string, "%Y-%m-%d")
                                                           rescue StandardError
                                                             nil
                                                           end)
        if effective_on.blank?
          notify("acapi.error.events.employer.renewal_transmission_authorized.invalid_effective_on_date", {
                   :fein => employer_fein,
                   :employer_id => employer_id,
                   :effective_on => effective_on_string,
                   :return_status => "422"
                 })
          return
        end
        employer = if employer_id.blank?
                     ::BenefitSponsors::Organizations::Organization.employer_by_fein(employer_fein).first
                   else
                     ::BenefitSponsors::Organizations::Organization.employer_by_hbx_id(employer_id).first
                   end
        if employer.nil?
          notify("acapi.error.events.employer.renewal_transmission_authorized.employer_not_found", {
                   :fein => employer_fein,
                   :employer_id => employer_id,
                   :effective_on => effective_on_string,
                   :return_status => "422"
                 })
        else
=begin
          termination_results = Queries::NamedPolicyQueries.shop_monthly_terminations([employer.fein], effective_on)
          termination_results.each do |termed_enrollment_id|
            notify("acapi.info.events.hbx_enrollment.terminated", {
              :hbx_enrollment_id => termed_enrollment_id,
              :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
              :reply_to => "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"
            })
          end
=end
          query_results = Queries::NamedEnrollmentQueries.renewal_gate_lifted_enrollments(employer, effective_on)
          query_results.each do |hbx_enrollment_id|
            notify("acapi.info.events.hbx_enrollment.coverage_selected", {
                     :hbx_enrollment_id => hbx_enrollment_id,
                     :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#initial",
                     :reply_to => "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"
                   })
          end
        end
      rescue Exception => e
        error_payload = JSON.dump({
                                    :error => e.inspect,
                                    :message => e.message,
                                    :backtrace => e.backtrace
                                  })
        notify("acapi.error.events.employer.renewal_transmission_authorized.unknown_error", {
                 :fein => employer_fein,
                 :employer_id => employer_id,
                 :effective_on => effective_on_string,
                 :return_status => "500",
                 :body => error_payload
               })
      end
    end
  end
end
