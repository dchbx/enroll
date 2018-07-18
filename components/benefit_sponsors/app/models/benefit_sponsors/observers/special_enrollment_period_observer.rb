module BenefitSponsors
  module Observers
    class SpecialEnrollmentPeriodObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? &&  new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          special_enrollment_period = new_model_event.klass_instance
          if (new_model_event.event_key == :employee_sep_request_accepted) && special_enrollment_period.is_shop?
            person = special_enrollment_period.family.primary_applicant.person
            unless person.has_multiple_active_employers?
              employee_role = person.active_employee_roles[0]
              deliver(recipient: employee_role, event_object: special_enrollment_period, notice_event: "employee_sep_request_accepted") 
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
