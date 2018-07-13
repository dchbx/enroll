module BenefitSponsors
  module Importers
    class ConversionEmployeePolicyAction < ::Importers::ConversionEmployeePolicyAction

      def find_benefit_group_assignment
        return @found_benefit_group_assignment unless @found_benefit_group_assignment.nil?
        census_employee = find_employee
        return nil unless census_employee

        found_employer = find_employer
        benefit_application = find_employer.active_benefit_application

        if benefit_application
          candidate_bgas = census_employee.benefit_group_assignments.where(:"benefit_package_id".in  => benefit_application.benefit_packages.map(&:id))
          @found_benefit_group_assignment = candidate_bgas.sort_by(&:start_on).last
        end
      end

      def find_employee
        return @found_employee unless @found_employee.nil?
        return nil if subscriber_ssn.blank?
        found_employer = find_employer
        return nil if found_employer.nil?
        benefit_sponsorship = found_employer.active_benefit_sponsorship
        candidate_employees = CensusEmployee.where({
                                                       benefit_sponsors_employer_profile_id: found_employer.id,
                                                       benefit_sponsorship_id: benefit_sponsorship.id,
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
        sponsor_benefit = find_sponsor_benefit
        return nil if sponsor_benefit.blank?
        sponsor_benefit.product_package.products.where(hios_id: corrected_hios_id).first
      end

      def find_sponsor_benefit
        employer = find_employer
        if benefit_application = employer.active_benefit_application
          benefit_package = benefit_application.benefit_packages.first
          benefit_package.sponsored_benefits.first
        end
      end

      def find_employer
        return @found_employer unless @found_employer.nil?
        org = BenefitSponsors::Organizations::Organization.where(:fein => fein).first
        return nil unless org
        @found_employer = org.employer_profile
      end

      # TODO: update references for plan years with benefit applications
      def save
        return false unless valid?
        employer = find_employer
        employee = find_employee
        employee_role = employee.employee_role
        benefit_application = employer.active_benefit_application
        benefit_package = benefit_application.benefit_packages.first

        if find_benefit_group_assignment.blank?
          if benefit_application
            has_active_state = BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES.include?(benefit_application.aasm_state)
            employee.benefit_group_assignments << BenefitGroupAssignment.new({
                                                                                 benefit_package_id: benefit_package.id,
                                                                                 start_on: benefit_application.start_on,
                                                                                 is_active: has_active_state})
            employee.save
          end
        end

        is_new = true
        if employee_role.present? && find_enrollments(employee_role).present?
          is_new = false
        end

        proxy = is_new ? BenefitSponsors::Importers::ConversionEmployeePolicy.new(@original_attributes) : ::Importers::ConversionEmployeePolicyUpdate.new(@original_attributes)
        result = proxy.save
        propagate_warnings(proxy)
        propagate_errors(proxy)
        result
      end

      def find_enrollments(employee_role)
        person = employee_role.person

        family = person.primary_family
        return [] if family.blank?

        employer = find_employer
        sponsor_ship = employer.active_benefit_sponsorship
        benefit_application = employer.active_benefit_application
        # plan_years = employer.plan_years.select {|py| py.coverage_period_contains?(start_date)}
        # active_plan_year = plan_years.detect {|py| (PlanYear::PUBLISHED + ['expired']).include?(py.aasm_state.to_s)}
        return [] if benefit_application.blank?

        family.active_household.hbx_enrollments.where({
                                                          :benefit_sponsorship_id => sponsor_ship.id,
                                                          :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES + ["coverage_expired"]
                                                      })
      end
    end
  end
end

