# frozen_string_literal: true

module Subscribers
  class EmployeeRenewalInvitationsSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.plan_year.employee_renewal_invitations_requested"]
    end

    def call(_event_name, _e_start, _e_end, _msg_id, payload)
      process_response(payload)
    end

    private

    def process_response(payload)
      stringified_payload = payload.stringify_keys
      benefit_application_id = stringified_payload["benefit_application_id"]
      benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.find(benefit_application_id)
      benefit_application.send_employee_renewal_invites
    rescue StandardError => e
      notify("acapi.error.application.enroll.remote_listener.employee_renewal_invitations_subscriber", {
               :body => JSON.dump({
                                    :error => e.inspect,
                                    :message => e.message,
                                    :backtrace => e.backtrace
                                  })
             })
    end

  end
end
