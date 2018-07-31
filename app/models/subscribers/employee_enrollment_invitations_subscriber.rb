module Subscribers
  class EmployeeEnrollmentInvitationsSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.plan_year.employee_enrollment_invitations_requested"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      begin
        stringified_payload = payload.stringify_keys
        benefit_application_id = stringified_payload["benefit_application_id"]
        benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.find(benefit_application_id)
        benefit_application.send_active_employee_invites
      rescue => e
        notify("acapi.error.application.enroll.remote_listener.employee_enrollment_invitations_subscriber", {
          :body => JSON.dump({
             :error => e.inspect,
             :message => e.message,
             :backtrace => e.backtrace
          })})
      end
    end

  end
end
