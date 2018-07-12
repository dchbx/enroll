module BenefitSponsors
  module Observers
    class CensusEmployeeObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? &&  new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          census_employee = new_model_event.klass_instance

          if ::CensusEmployee::OTHER_EVENTS.include?(new_model_event.event_key)
            deliver(recipient: census_employee.employee_role, event_object: new_model_event.options[:event_object], notice_event: new_model_event.event_key.to_s)
          end

          if ::CensusEmployee::REGISTERED_EVENTS.include?(new_model_event.event_key)
            if new_model_event.event_key == :employee_notice_for_employee_terminated_from_roster
              deliver(recipient: census_employee.employee_role, event_object: census_employee, notice_event: "employee_notice_for_employee_terminated_from_roster")
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
