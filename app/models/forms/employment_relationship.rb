# frozen_string_literal: true

module Forms
  class EmploymentRelationship
    include ActiveModel::Model

    attr_accessor :employer_name, :hired_on, :eligible_for_coverage_on, :census_employee_id, :gender, :no_ssn

    include ::Forms::PeopleNames

    def census_employee
      ::CensusEmployee.find(census_employee_id)
    end


  end
end
