# frozen_string_literal: true

module Forms
  class EmployeeRole < SimpleDelegator
    WRAPPED_ATTRIBUTES = [
      "employee_role_id"
    ].freeze

    attr_accessor(*WRAPPED_ATTRIBUTES)

    def initialize(person, employee_role = nil)
      super(person)
      self.employee_role_id = employee_role.id if employee_role
    end

    def self.model_name
      Person.model_name
    end

    def self.find(id)
      self.new(Person.find(id))
    end

    def clean_attributes(hsh)
      atts = hsh.dup.stringify_keys
      for_wrapper, for_person = atts.partition { |k, _v| WRAPPED_ATTRIBUTES.include?(k) }
      [Hash[for_wrapper], Hash[for_person]]
    end

    def update_attributes(hsh)
      for_wrapper, for_person = clean_attributes(hsh.to_h)
      for_wrapper.each_pair do |k,v|
        self.send("#{k}=", v)
      end
      super(for_person)
    end

    def benefit_group
      @benefit_group ||= employee_role.benefit_group
    end

    def organization_id
      organization.id
    end

    def organization
      @organization ||= employer_profile.organization
    end

    def employer_profile
      @employer_profile ||= self.employee_role.employer_profile
    end

    def census_employee
      @census_employee ||= employee_role.new_census_employee
    end

    def employee_role
      @employee_role ||= __getobj__.employee_roles.detect { |role| role.id.to_s == self.employee_role_id.to_s }
    end
  end
end
