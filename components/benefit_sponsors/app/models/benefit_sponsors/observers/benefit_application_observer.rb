module BenefitSponsors
  module Observers
    class BenefitApplicationObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? && new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)

          if BenefitSponsors::ModelEvents::BenefitApplication::REGISTERED_EVENTS.include?(new_model_event.event_key)
            benefit_application = new_model_event.klass_instance

            if new_model_event.event_key == :application_submitted
              trigger_zero_employees_on_roster_notice(benefit_application)
              if benefit_application.is_renewing?
                deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "renewal_application_published")
              else
                deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "initial_application_submitted")
              end
            end

            # if new_model_event.event_key == :zero_employees_on_roster
            #   trigger_zero_employees_on_roster_notice(benefit_application)
            # end

            if new_model_event.event_key == :employer_open_enrollment_completed
              policy = enrollment_policy.business_policies_for(benefit_application, :end_open_enrollment)
              if policy.is_satisfied?(benefit_application)
                notice_event = benefit_application.is_renewing? ? "renewal_employer_open_enrollment_completed" : "initial_employer_open_enrollment_completed"
                deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: notice_event)
                
                if benefit_application.is_renewing?
                  benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
                    enrollments = ce.renewal_benefit_group_assignment.hbx_enrollments
                    enrollment = enrollments.select{ |enr| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES).include?(enr.aasm_state) }.sort_by(&:updated_at).last
                    if enrollment.employee_role.present?
                      deliver(recipient: enrollment.employee_role, event_object: enrollment, notice_event: "renewal_employee_enrollment_confirmation")
                    end
                  end
                end
              end
            end

            if new_model_event.event_key == :renewal_application_created
              deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "renewal_application_created")
            end

            if new_model_event.event_key == :renewal_application_autosubmitted
              deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "plan_year_auto_published") if benefit_application.is_renewing?
              trigger_zero_employees_on_roster_notice(benefit_application)
            end

            if new_model_event.event_key == :ineligible_application_submitted
              policy = eligibility_policy.business_policies_for(benefit_application, :submit_benefit_application)
              unless policy.is_satisfied?(benefit_application)
                if benefit_application.is_renewing?
                  if policy.fail_results.include?(:employer_primary_office_location)
                    deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "employer_renewal_eligibility_denial_notice")
                    benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
                      if ce.employee_role.present?
                        deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "termination_of_employers_health_coverage")
                      end
                    end
                  end
                elsif (policy.fail_results.include?(:employer_primary_office_location) || policy.fail_results.include?(:benefit_application_fte_count))
                  deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "employer_initial_eligibility_denial_notice")
                end
              end
            end

            if new_model_event.event_key == :application_denied
              policy = enrollment_policy.business_policies_for(benefit_application, :end_open_enrollment)
              unless policy.is_satisfied?(benefit_application)
                if (policy.fail_results.include?(:minimum_participation_rule) || policy.fail_results.include?(:non_business_owner_enrollment_count))
                  employer_notice_event = benefit_application.is_renewing? ? "renewal_employer_ineligibility_notice" : "initial_employer_application_denied"
                  employee_notice_event = benefit_application.is_renewing? ? "employee_renewal_employer_ineligibility_notice" : "group_ineligibility_notice_to_employee"
                  deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: employer_notice_event)
                  benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
                    if ce.employee_role.present?
                      deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: employee_notice_event)
                    end
                  end
                end
              end
            end
          end

          if BenefitSponsors::ModelEvents::BenefitApplication::DATA_CHANGE_EVENTS.include?(new_model_event.event_key)
            current_date = TimeKeeper.date_of_record
            if new_model_event.event_key == :low_enrollment_notice_for_employer
              BenefitSponsors::Queries::NoticeQueries.organizations_for_low_enrollment_notice(current_date).each do |benefit_sponsorship|
               begin
                 benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :enrollment_open).sort_by(&:created_at).last
                  next if benefit_application.effective_period.min.yday == 1
                  if benefit_application.enrollment_ratio < benefit_application.benefit_market.configuration.ee_ratio_min
                    deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: "low_enrollment_notice_for_employer")
                  end
                end
              end
            end

            if [:renewal_employer_publish_plan_year_reminder_after_soft_dead_line,
                :renewal_plan_year_first_reminder_before_soft_dead_line,
                :renewal_plan_year_publish_dead_line].include?(new_model_event.event_key)
              BenefitSponsors::Queries::NoticeQueries.organizations_for_force_publish(current_date).each do |benefit_sponsorship|
                benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).detect { |ba| ba.is_renewing? }
                if benefit_application.present? && benefit_application.is_renewing?
                  deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: new_model_event.event_key.to_s)
                end
              end
            end

            if [:initial_employer_first_reminder_to_publish_plan_year,
                :initial_employer_second_reminder_to_publish_plan_year,
                :initial_employer_final_reminder_to_publish_plan_year].include?(new_model_event.event_key)
              start_on = TimeKeeper.date_of_record.next_month.beginning_of_month
              benefit_sponsorships = BenefitSponsors::Queries::NoticeQueries.initial_employers_by_effective_on_and_state(start_on: start_on, aasm_state: :draft)
              benefit_sponsorships.each do|benefit_sponsorship|
                benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state => :draft).sort_by(&:created_at).last
                unless benefit_application.is_renewing?
                  deliver(recipient: benefit_sponsorship.profile, event_object: benefit_application, notice_event: new_model_event.event_key.to_s)
                end
              end
            end

            if new_model_event.event_key == :initial_employer_no_binder_payment_received
              BenefitSponsors::Queries::NoticeQueries.initial_employers_in_enrolled_state.each do |benefit_sponsorship|
                if !benefit_sponsorship.initial_enrollment_eligible?
                  eligible_states = BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLMENT_ELIGIBLE_STATES + BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLING_STATES
                  benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state.in => eligible_states).first
                  unless benefit_application.is_renewing?
                    deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "initial_employer_no_binder_payment_received")
                    #Notice to employee that there employer misses binder payment
                    benefit_sponsorship.census_employees.active.each do |ce|
                      begin
                        deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "notice_to_ee_that_er_plan_year_will_not_be_written")
                      end
                    end
                  end
                end
              end
            end
          end

          if BenefitSponsors::ModelEvents::BenefitApplication::OTHER_EVENTS.include?(new_model_event.event_key)
            benefit_application = new_model_event.klass_instance
            if new_model_event.event_key == :group_advance_termination_confirmation
              deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "group_advance_termination_confirmation")

              benefit_application.benefit_sponsorship.census_employees.non_terminated.each do |ce|
                deliver(recipient: ce.employee_role, event_object: benefit_application, notice_event: "notify_employee_of_group_advance_termination") if ce.employee_role
              end
            end
          end
        end
      end

      def trigger_zero_employees_on_roster_notice(benefit_application)
        # TODO: Update the query to exclude congressional employees
        # if !benefit_application.benefit_packages.any?{|bg| bg.is_congress?} && benefit_application.benefit_sponsorship.census_employees.active.count < 1
        if benefit_application.benefit_sponsorship.census_employees.active.count < 1
          deliver(recipient: benefit_application.employer_profile, event_object: benefit_application, notice_event: "zero_employees_on_roster_notice")
        end
      end

      private

      def initialize
        @notifier = BenefitSponsors::Services::NoticeService.new
      end

      def deliver(recipient:, event_object:, notice_event:, notice_params: {})
        notifier.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: notice_params)
      end

      def eligibility_policy
        return @eligibility_policy if defined? @eligibility_policy
        @eligibility_policy = BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new
      end

      def enrollment_policy
        return @enrollment_policy if defined? @enrollment_policy
        @enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
      end

    end
  end
end
