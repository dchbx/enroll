module Observers
  class NoticeObserver < Observer

    def plan_year_update(new_model_event)
      current_date = TimeKeeper.date_of_record
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if PlanYear::REGISTERED_EVENTS.include?(new_model_event.event_key)
        plan_year = new_model_event.klass_instance

        if new_model_event.event_key == :renewal_application_denied
          errors = plan_year.enrollment_errors

          if(errors.include?(:eligible_to_enroll_count) || errors.include?(:non_business_owner_enrollment_count))
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_ineligibility_notice")

            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "employee_renewal_employer_ineligibility_notice")
              end
            end
          end
        end

        if new_model_event.event_key == :initial_application_submitted
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "initial_application_submitted")
          trigger_zero_employees_on_roster_notice(plan_year)
        end

        if new_model_event.event_key == :zero_employees_on_roster
          trigger_zero_employees_on_roster_notice(plan_year)
        end

        if new_model_event.event_key == :renewal_employer_open_enrollment_completed
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_open_enrollment_completed")
        end

        if new_model_event.event_key == :renewal_application_submitted
          trigger_zero_employees_on_roster_notice(plan_year)
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_published")
        end

        if new_model_event.event_key == :initial_employer_open_enrollment_completed
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "initial_employer_open_enrollment_completed")
        end

        if new_model_event.event_key == :renewal_application_created
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_created")
        end

        if new_model_event.event_key == :renewal_application_autosubmitted
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "plan_year_auto_published")
          trigger_zero_employees_on_roster_notice(plan_year)
        end

        if new_model_event.event_key == :group_advance_termination_confirmation
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "group_advance_termination_confirmation")

          plan_year.employer_profile.census_employees.active.each do |ce|
            trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "notify_employee_of_group_advance_termination")
          end
        end
        
        if new_model_event.event_key == :ineligible_initial_application_submitted
          if (plan_year.application_eligibility_warnings.include?(:primary_office_location) || plan_year.application_eligibility_warnings.include?(:fte_count))
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "employer_initial_eligibility_denial_notice")
          end
        end

        if new_model_event.event_key == :ineligible_renewal_application_submitted

          if plan_year.application_eligibility_warnings.include?(:primary_office_location)
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "employer_renewal_eligibility_denial_notice")
            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "termination_of_employers_health_coverage")
              end
            end
          end
        end

        if new_model_event.event_key == :renewal_enrollment_confirmation
          trigger_notice(recipient: plan_year.employer_profile,  event_object: plan_year, notice_event: "renewal_employer_open_enrollment_completed" )
          plan_year.employer_profile.census_employees.non_terminated.each do |ce|
            enrollments = ce.renewal_benefit_group_assignment.hbx_enrollments
            enrollment = enrollments.select{ |enr| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES).include?(enr.aasm_state) }.sort_by(&:updated_at).last
            if enrollment.present?
              trigger_notice(recipient: ce.employee_role, event_object: enrollment, notice_event: "renewal_employee_enrollment_confirmation")
            end
          end
        end

        if new_model_event.event_key == :application_denied
          errors = plan_year.enrollment_errors
          if(errors.include?(:enrollment_ratio) || errors.include?(:non_business_owner_enrollment_count))
            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "group_ineligibility_notice_to_employee")
              end
            end
          end
        end

        if PlanYear::DATA_CHANGE_EVENTS.include?(new_model_event.event_key)
        end
      end
    end

    def employer_profile_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if EmployerProfile::REGISTERED_EVENTS.include?(new_model_event.event_key)
        employer_profile = new_model_event.klass_instance
        if new_model_event.event_key == :initial_employee_plan_selection_confirmation
          if employer_profile.is_new_employer?
            census_employees = employer_profile.census_employees.non_terminated
            census_employees.each do |ce|
              if ce.active_benefit_group_assignment.hbx_enrollment.present? && ce.active_benefit_group_assignment.hbx_enrollment.effective_on == employer_profile.plan_years.where(:aasm_state.in => ["enrolled", "enrolling"]).first.start_on
                trigger_notice(recipient: ce.employee_role, event_object: ce.active_benefit_group_assignment.hbx_enrollment, notice_event: "initial_employee_plan_selection_confirmation")
              end
            end
          end
        end
      end

      if EmployerProfile::OTHER_EVENTS.include?(new_model_event.event_key)
        employer_profile = new_model_event.klass_instance
        if new_model_event.event_key == :broker_hired_confirmation_to_employer
          trigger_notice(recipient: employer_profile, event_object: employer_profile, notice_event: "broker_hired_confirmation_to_employer")
        elsif new_model_event.event_key == :welcome_notice_to_employer
          trigger_notice(recipient: employer_profile, event_object: employer_profile, notice_event: "welcome_notice_to_employer")
        end
      end
    end

    def hbx_enrollment_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if HbxEnrollment::REGISTERED_EVENTS.include?(new_model_event.event_key)
        hbx_enrollment = new_model_event.klass_instance
        if hbx_enrollment.is_shop? && hbx_enrollment.census_employee.is_active?
          
          is_valid_employer_py_oe = (hbx_enrollment.benefit_group.plan_year.open_enrollment_contains?(hbx_enrollment.submitted_at) || hbx_enrollment.benefit_group.plan_year.open_enrollment_contains?(hbx_enrollment.created_at))

          if new_model_event.event_key == :notify_employee_of_plan_selection_in_open_enrollment
            if is_valid_employer_py_oe
              trigger_notice(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "notify_employee_of_plan_selection_in_open_enrollment") #renewal EE notice
            end
          end

          if new_model_event.event_key == :application_coverage_selected
            if is_valid_employer_py_oe
              trigger_notice(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "notify_employee_of_plan_selection_in_open_enrollment") #initial EE notice
            end
            
            if !is_valid_employer_py_oe && (hbx_enrollment.enrollment_kind == "special_enrollment" || hbx_enrollment.census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record))
              trigger_notice(recipient: hbx_enrollment.census_employee.employee_role, event_object: hbx_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")
            end
          end

        end

        if new_model_event.event_key == :employee_waiver_confirmation
          trigger_notice(recipient: hbx_enrollment.census_employee.employee_role, event_object: hbx_enrollment, notice_event: "employee_waiver_confirmation")
        end

        if new_model_event.event_key == :employee_coverage_termination
          if hbx_enrollment.is_shop? && (CensusEmployee::EMPLOYMENT_ACTIVE_STATES - CensusEmployee::PENDING_STATES).include?(hbx_enrollment.census_employee.aasm_state) && hbx_enrollment.benefit_group.plan_year.active?
            trigger_notice(recipient: hbx_enrollment.employer_profile, event_object: hbx_enrollment, notice_event: "employer_notice_for_employee_coverage_termination")
            trigger_notice(recipient: hbx_enrollment.employee_role, event_object: hbx_enrollment, notice_event: "employee_notice_for_employee_coverage_termination")
          end
        end
      end
    end

    def plan_year_date_change(model_event)
      current_date = TimeKeeper.date_of_record
      if PlanYear::DATA_CHANGE_EVENTS.include?(model_event.event_key)
        if model_event.event_key == :renewal_employer_publish_plan_year_reminder_after_soft_dead_line
          trigger_on_queried_records("renewal_employer_publish_plan_year_reminder_after_soft_dead_line")
        end

        if model_event.event_key == :renewal_plan_year_first_reminder_before_soft_dead_line
          trigger_on_queried_records("renewal_plan_year_first_reminder_before_soft_dead_line")
        end

        if model_event.event_key == :renewal_plan_year_publish_dead_line
          trigger_on_queried_records("renewal_plan_year_publish_dead_line")
        end

        if model_event.event_key == :low_enrollment_notice_for_employer
          organizations_for_low_enrollment_notice(current_date).each do |organization|
           begin
             plan_year = organization.employer_profile.plan_years.where(:aasm_state.in => ["enrolling", "renewing_enrolling"]).first
             #exclude congressional employees
              next if ((plan_year.benefit_groups.any?{|bg| bg.is_congress?}) || (plan_year.effective_date.yday == 1))
              if plan_year.enrollment_ratio < Settings.aca.shop_market.employee_participation_ratio_minimum
                trigger_notice(recipient: organization.employer_profile, event_object: plan_year, notice_event: "low_enrollment_notice_for_employer")
              end
            end
          end
        end

        if model_event.event_key == :initial_employer_no_binder_payment_received
          EmployerProfile.initial_employers_enrolled_plan_year_state.each do |org|
            if !org.employer_profile.binder_paid?
              py = org.employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ENROLLING_STATE).first
              trigger_notice(recipient: org.employer_profile, event_object: py, notice_event: "initial_employer_no_binder_payment_received")
            end
          end
        end

        if model_event.event_key == :initial_employer_first_reminder_to_publish_plan_year
          trigger_initial_employer_publish_remainder("initial_employer_first_reminder_to_publish_plan_year")
        end

        if model_event.event_key == :initial_employer_second_reminder_to_publish_plan_year
          trigger_initial_employer_publish_remainder("initial_employer_second_reminder_to_publish_plan_year")
        end

        if model_event.event_key == :initial_employer_final_reminder_to_publish_plan_year
          trigger_initial_employer_publish_remainder("initial_employer_final_reminder_to_publish_plan_year")
        end

      end
    end

    def special_enrollment_period_update(new_model_event)
      special_enrollment_period = new_model_event.klass_instance

      if special_enrollment_period.is_shop?
        primary_applicant = special_enrollment_period.family.primary_applicant
        if employee_role = primary_applicant.person.active_employee_roles[0]
          trigger_notice(recipient: employee_role, event_object: special_enrollment_period, notice_event: "employee_sep_request_accepted") 
        end
      end
    end

    def employer_profile_date_change; end
    def hbx_enrollment_date_change; end
    def census_employee_date_change; end
    def special_enrollment_period_date_change; end

    def census_employee_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)
      census_employee = new_model_event.klass_instance
      if CensusEmployee::OTHER_EVENTS.include?(new_model_event.event_key)
        trigger_notice(recipient: census_employee.employee_role, event_object: new_model_event.options[:event_object], notice_event: new_model_event.event_key.to_s)
      end

      if  CensusEmployee::REGISTERED_EVENTS.include?(new_model_event.event_key)
        if new_model_event.event_key == :employee_notice_for_employee_terminated_from_roster
          trigger_notice(recipient: census_employee.employee_role, event_object: census_employee, notice_event: "employee_notice_for_employee_terminated_from_roster")
        end
      end
    end

    def trigger_zero_employees_on_roster_notice(plan_year)
      if !plan_year.benefit_groups.any?{|bg| bg.is_congress?} && plan_year.employer_profile.census_employees.active.count < 1
        trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "zero_employees_on_roster_notice")
      end
    end

    def trigger_on_queried_records(event_name)
      current_date = TimeKeeper.date_of_record
      organizations_for_force_publish(current_date).each do |organization|
        plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'renewing_draft').first
        trigger_notice(recipient: organization.employer_profile, event_object: plan_year, notice_event:event_name)
      end
    end

    def organizations_for_low_enrollment_notice(current_date)
      Organization.where(:"employer_profile.plan_years" =>
        { :$elemMatch => {
          :"aasm_state".in => ["enrolling", "renewing_enrolling"],
          :"open_enrollment_end_on" => current_date+2.days
          }
      })
    end

    def trigger_initial_employer_publish_remainder(event_name)
      start_on_1 = (TimeKeeper.date_of_record+1.month).beginning_of_month
      initial_employers_reminder_to_publish(start_on_1).each do|organization|
        plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'draft').first
        trigger_notice(recipient: organization.employer_profile, event_object: plan_year, notice_event:event_name)
      end
    end
  end
end