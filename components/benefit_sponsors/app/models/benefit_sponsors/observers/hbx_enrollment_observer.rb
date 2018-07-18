module BenefitSponsors
  module Observers
    class HbxEnrollmentObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? &&  new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          if ::HbxEnrollment::REGISTERED_EVENTS.include?(new_model_event.event_key)
            hbx_enrollment = new_model_event.klass_instance

            if hbx_enrollment.is_shop? && hbx_enrollment.census_employee && hbx_enrollment.census_employee.is_active?

              is_valid_employer_py_oe = (hbx_enrollment.sponsored_benefit_package.benefit_application.open_enrollment_period.cover?(hbx_enrollment.submitted_at) || hbx_enrollment.sponsored_benefit_package.benefit_application.open_enrollment_period.cover?(hbx_enrollment.created_at))

              if new_model_event.event_key == :notify_employee_of_plan_selection_in_open_enrollment
                if is_valid_employer_py_oe
                  deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "notify_employee_of_plan_selection_in_open_enrollment") #renewal EE notice
                elsif !is_valid_employer_py_oe && (hbx_enrollment.enrollment_kind == "special_enrollment" || hbx_enrollment.census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record))
                  deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employee_mid_year_plan_change_notice_to_employer") #MAG043 - notice to employer - renewal case
                end
              end

              if new_model_event.event_key == :application_coverage_selected
                if is_valid_employer_py_oe
                  deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "notify_employee_of_plan_selection_in_open_enrollment") #initial EE notice
                end

                if !is_valid_employer_py_oe && (hbx_enrollment.enrollment_kind == "special_enrollment" || hbx_enrollment.census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record))
                  deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employee_mid_year_plan_change_notice_to_employer") #MAG043 - notice to employer
                  deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")
                end
              end
            end

            if new_model_event.event_key == :employee_waiver_confirmation
              deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_waiver_confirmation")
            end

            if new_model_event.event_key == :employee_coverage_termination
              if hbx_enrollment.is_shop? && (::CensusEmployee::EMPLOYMENT_ACTIVE_STATES - ::CensusEmployee::PENDING_STATES).include?(hbx_enrollment.census_employee.aasm_state) && hbx_enrollment.sponsored_benefit_package.is_active
                deliver(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employer_notice_for_employee_coverage_termination")
                deliver(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_notice_for_employee_coverage_termination")
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
