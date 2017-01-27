module Factories
  class EmploymentRelationshipFactory
    def initialize

    end

    def build(employee_candidate, census_employee)
      benefit_group = (census_employee.active_benefit_group_assignment || census_employee.renewal_benefit_group_assignment).benefit_group
      hired_on = census_employee.hired_on
      employer = census_employee.employer_profile

      effective_on_date = benefit_group.effective_on_for(census_employee.hired_on)

      if census_employee.newly_designated_eligible? || census_employee.newly_designated_linked?
        effective_on_date = [effective_on_date, census_employee.newly_eligible_earlist_eligible_date].max
      end

      ::Forms::EmploymentRelationship.new({
        :employer_name => employer.legal_name,
        :first_name => employee_candidate.first_name,
        :last_name => employee_candidate.last_name,
        :middle_name => employee_candidate.middle_name,
        :name_pfx => employee_candidate.name_pfx,
        :name_sfx => employee_candidate.name_sfx,
        :gender => employee_candidate.gender,
        :census_employee_id => census_employee.id,
        :hired_on => hired_on,
        :eligible_for_coverage_on => effective_on_date
      })
    end

    def self.build(employee_candidate, census_employee)
      factory = self.new
      Array(census_employee).map { |c_employee| factory.build(employee_candidate, c_employee) }
    end
  end
end
