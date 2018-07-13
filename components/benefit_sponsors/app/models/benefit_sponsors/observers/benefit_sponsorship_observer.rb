module BenefitSponsors
  module Observers
    class BenefitSponsorshipObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? &&  new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          benefit_sponsorship = new_model_event.klass_instance
          employer_profile = benefit_sponsorship.profile
          if BenefitSponsors::ModelEvents::BenefitSponsorship::REGISTERED_EVENTS.include?(new_model_event.event_key)
            if new_model_event.event_key == :initial_employee_plan_selection_confirmation
              if employer_profile.is_new_employer?
                census_employees = benefit_sponsorship.census_employees.non_terminated
                census_employees.each do |ce|
                  if ce.active_benefit_group_assignment.hbx_enrollment.present? && ce.active_benefit_group_assignment.hbx_enrollment.effective_on == employer_profile.active_benefit_sponsorship.benefit_applications.where(:aasm_state.in => [:enrollment_eligible, :enrollment_closed]).first.start_on
                    deliver(recipient: ce.employee_role, event_object: ce.active_benefit_group_assignment.hbx_enrollment, notice_event: "initial_employee_plan_selection_confirmation")
                  end
                end
              end
            end
          end
        end
      end

      private

      def initialize
        @notifier = BenefitSponsors::Services::NoticeService.new
      end

      def deliver(recipient:, event_object:, notice_event:, notice_params: {})
        notifier.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: notice_params)
      end
    end
  end
end
