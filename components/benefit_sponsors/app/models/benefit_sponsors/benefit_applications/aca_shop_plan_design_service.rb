module BenefitSponsors
  class BenefitApplications::AcaShopPlanDesignService

    def initialize(benefit_application)
      @benefit_application = benefit_application
    end

      # validate :validate_application_dates


      # TODO Refactor - Move this to Domain logic
      # after_update :update_employee_benefit_packages
      # TODO: Refactor code into benefit package updater
      # def update_employee_benefit_packages
      #   if self.start_on_changed?
      #     bg_ids = self.benefit_groups.pluck(:_id)
      #     employees = CensusEmployee.where({ :"benefit_group_assignments.benefit_group_id".in => bg_ids })
      #     employees.each do |census_employee|
      #       census_employee.benefit_group_assignments.where(:benefit_group_id.in => bg_ids).each do |assignment|
      #         assignment.update(start_on: self.start_on)
      #         assignment.update(end_on: self.end_on) if assignment.end_on.present?
      #       end
      #     end
      #   end
      # end


      # TODO Refactor - Move this to Domain logic
      # def assigned_census_employees
      #   benefit_packages.flat_map(){ |benefit_package| benefit_package.census_employees.active }
      # end

      # TODO Refactor - Move this to Domain logic
      ## Stub for BQT
      # def estimate_group_size?
      #   true
      # end

      # TODO Refactor - Move this to Domain logic
      # def eligible_for_export?
      #   return false if self.aasm_state.blank?
      #   return false if self.is_conversion
      #   !INELIGIBLE_FOR_EXPORT_STATES.include?(self.aasm_state.to_s)
      # end




      # # TODO: Refactor -- where is this used?
      # # def to_plan_year
      # #   BenefitApplicationToPlanYearConverter.new(self).call
      # # end
    end

  end
