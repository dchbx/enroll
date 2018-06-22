module Subscribers
  class EmployeeRenewalInvitationsSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.plan_year.employee_renewal_invitations_requested"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      begin
        stringified_payload = payload.stringify_keys
        plan_year_id = stringified_payload["plan_year_id"]
        plan_year = PlanYear.find(plan_year_id)
        plan_year.send_employee_renewal_invites
      rescue => e
        notify("acapi.error.application.enroll.remote_listener.employee_renewal_invitations_subscriber", {
          :body => JSON.dump({
             :error => e.inspect,
             :message => e.message,
             :backtrace => e.backtrace
          })})
      end
    end

  end
end
