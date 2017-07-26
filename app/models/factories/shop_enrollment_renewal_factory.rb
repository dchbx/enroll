module Factories
  class ShopEnrollmentRenewalFactory
    include EnrollmentRenewalBuilder

    attr_accessor :family, :census_employee, :employer, :renewing_plan_year, :enrollment, :is_waiver, :coverage_kind

    def initialize(params)
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      @plan_year_start_on = renewing_plan_year.start_on if renewing_plan_year.present?
    end

    def renew_coverage
      verify_and_populate_benefit_group_assignment

      if is_waiver
        renew_waived_enrollment
      else
        generate_passive_renewal
      end
    end

    def update_passive_renewal
      set_instance_variables
      validate_employer
      verify_and_populate_benefit_group_assignment

      passive_renewals.each do |renewal|
        renewal.cancel_coverage! if renewal.may_cancel_coverage?
      end

      if active_renewals.blank?
        if is_coverage_active? && renewal_plan_offered_by_er?(enrollment)
          generate_passive_renewal
        else
          @enrollment = current_enrollments.where(:aasm_state => 'inactive').first
          renew_waived_enrollment
        end
      end
    end

    def active_renewals
      renewal_enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['inactive'])
    end

    def passive_renewals
      renewal_enrollments.where(:aasm_state.in => HbxEnrollment::RENEWAL_STATUSES + ['renewing_waived'])
    end

    def renewal_enrollments
      enrollments_by_plan_year(renewing_plan_year).where({:effective_on => renewing_plan_year.start_on })
    end

    def current_enrollments
      enrollments_by_plan_year(employer.active_plan_year)
    end

    def active_enrollments
      current_enrollments.where(:aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending'])).order(:"submitted_at".desc)
    end

    def is_coverage_active?
      (HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending']).include?(enrollment.aasm_state)
    end

    private 

    def enrollments_by_plan_year(plan_year)
      family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => plan_year.benefit_groups.pluck(:_id), 
        :coverage_kind => enrollment.coverage_kind,
        :kind => enrollment.kind
      })
    end

    def set_instance_variables
      @family = enrollment.family
      @coverage_kind = enrollment.coverage_kind

      if enrollment.employee_role.present?
        @census_employee = enrollment.employee_role.census_employee
      elsif enrollment.benefit_group_assignment.present?
        @census_employee = enrollment.benefit_group_assignment.census_employee
      end

      if @census_employee.present?
        @employer = @census_employee.employer_profile 
        @renewing_plan_year = @employer.renewing_published_plan_year
      end

      @plan_year_start_on = renewing_plan_year.start_on if renewing_plan_year.present?
    end

    def renewal_assignment
      assignment = renewing_plan_year.active? ? census_employee.active_benefit_group_assignment 
           : census_employee.renewal_benefit_group_assignment

      (assignment.present? && renewing_plan_year.benefit_groups.pluck(:_id).include?(assignment.benefit_group_id)) ? assignment : nil
    end

    def verify_and_populate_benefit_group_assignment
      if renewal_assignment.blank?
        benefit_group = renewing_plan_year.default_benefit_group || renewing_plan_year.benefit_groups.first
        if renewing_plan_year.active?
          census_employee.add_benefit_group_assignment(benefit_group, benefit_group.start_on)
        else
          census_employee.add_renew_benefit_group_assignment(benefit_group)
        end
        census_employee.save!
      end
    end

    def renewal_plan_offered_by_er?(enrollment)
      if enrollment.plan.present? || enrollment.plan.renewal_plan.present?
        benefit_group = renewal_assignment.try(:benefit_group) || renewing_plan_year.default_benefit_group || renewing_plan_year.benefit_groups.first
        elected_plan_ids = (enrollment.coverage_kind == 'health' ? benefit_group.elected_plan_ids : benefit_group.elected_dental_plan_ids)
        elected_plan_ids.include?(enrollment.plan.renewal_plan_id)
      else
        false
      end
    end

    def validate_employer
      if renewing_plan_year.blank?
        raise ShopEnrollmentRenewalFactoryError, "Renewing Plan year missing under employer #{employer.legal_name}"
      end

      if !['renewing_enrolling', 'renewing_enrolled'].include?(renewing_plan_year.aasm_state)
        raise ShopEnrollmentRenewalFactoryError, "Renewing Plan year OE not yet started under employer #{employer.legal_name}"
      end

      if employer.active_plan_year.blank?
        raise ShopEnrollmentRenewalFactoryError, "Active Plan year missing under employer #{employer.legal_name}"
      end
    end
  end

  class ShopEnrollmentRenewalFactoryError < StandardError; end
end


