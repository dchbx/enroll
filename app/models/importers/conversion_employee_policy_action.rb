module Importers
  class ConversionEmployeePolicyAction < ConversionEmployeePolicyCommon

    # validate :validate_benefit_group_assignment
    validate :validate_census_employee
    validate :validate_fein
    validate :validate_plan
    validates_length_of :fein, is: 9
    validates_length_of :subscriber_ssn, is: 9
    validates_presence_of :hios_id

    def initialize(opts = {})
      super(opts)
      @original_attributes = opts
    end

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      end
    end

    def validate_census_employee
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      if found_employee.nil?
        errors.add(:subscriber_ssn, "no census employee found")
      end
    end

    def validate_benefit_group_assignment
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      return true unless find_employee
      found_bga = find_benefit_group_assignment
      if found_bga.nil?
        errors.add(:subscriber_ssn, "no benefit group assignment found")
      end
    end

    def validate_plan
      return true if hios_id.blank?
      found_plan = find_plan
      if found_plan.nil?
        errors.add(:hios_id, "no plan found with hios_id #{hios_id} and active year #{plan_year}")
      end
    end

    def find_employee
      return @found_employee unless @found_employee.nil?
      return nil if subscriber_ssn.blank?
      found_employer = find_employer
      return nil if found_employer.nil?
      candidate_employees = CensusEmployee.where({
        employer_profile_id: found_employer.id,
        # hired_on: {"$lte" => start_date},
        encrypted_ssn: CensusMember.encrypt_ssn(subscriber_ssn)
      })
      non_terminated_employees = candidate_employees.reject do |ce|
        (!ce.employment_terminated_on.blank?) && ce.employment_terminated_on <= Date.today
      end
    
      @found_employee = non_terminated_employees.sort_by(&:hired_on).last
    end

    def find_plan 
      return @plan unless @plan.nil?
      return nil if hios_id.blank?
      clean_hios = hios_id.strip
      corrected_hios_id = (clean_hios.end_with?("-01") ? clean_hios : clean_hios + "-01")
      @plan = Plan.where({
        active_year: plan_year.to_i,
        hios_id: corrected_hios_id
      }).first
    end

    def find_employer
      return @found_employer unless @found_employer.nil?
      org = Organization.where(:fein => fein).first
      return nil unless org
      @found_employer = org.employer_profile
    end

    def save
      return false unless valid?
      employer = find_employer
      employee = find_employee
      employee_role = employee.employee_role

      if find_benefit_group_assignment.blank?
        if plan_year = employer.plan_years.published_and_expired_plan_years_by_date(employer.registered_on).first
          employee.benefit_group_assignments << BenefitGroupAssignment.new({ 
            benefit_group: plan_year.benefit_groups.first, 
            start_on: plan_year.start_on, 
            is_active: PlanYear::PUBLISHED.include?(plan_year.aasm_state)})
          employee.save
        end
      end

      is_new = true
      if employee_role.present? && find_enrollments(employee_role).present?
        is_new = false
      end

      proxy = is_new ? ::Importers::ConversionEmployeePolicy.new(@original_attributes) : ::Importers::ConversionEmployeePolicyUpdate.new(@original_attributes)
      result = proxy.save
      propagate_warnings(proxy)
      propagate_errors(proxy)
      result
    end

    def propagate_warnings(proxy)
      proxy.warnings.each do |attr, err|
        warnings.add(attr, err)
      end
    end

    def propagate_errors(proxy)
      proxy.errors.each do |attr, err|
        errors.add(attr, err)
      end
    end

    def find_enrollments(employee_role)
      person = employee_role.person

      family = person.primary_family
      return [] if family.blank?

      employer = find_employer
      plan_years = employer.plan_years.select{|py| py.coverage_period_contains?(start_date) }
      active_plan_year = plan_years.detect{|py| (PlanYear::PUBLISHED + ['expired']).include?(py.aasm_state.to_s)}
      return [] if active_plan_year.blank?

      family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => active_plan_year.benefit_group_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES + ["coverage_expired"]
        })
    end
  end
end
