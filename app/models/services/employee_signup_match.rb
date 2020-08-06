# frozen_string_literal: true

module Services
  class EmployeeSignupMatch
    def initialize(form_factory = Factories::MatchedEmployee, census_employee_finder = EmployerProfile)
      @form_factory = form_factory.new
      @census_employee_finder = census_employee_finder
    end

    def call(consumer_identity)
      census_employees = @census_employee_finder.find_census_employee_by_person(consumer_identity)
      return nil if census_employees.empty?
      census_employee = census_employees.first
      [census_employee, @form_factory.build(consumer_identity, census_employee, consumer_identity.match_person)]
    end
  end
end
