# frozen_string_literal: true

module Exchanges
  module HbxProfilesHelper
    def get_person_roles(person, person_roles = [])
      person_roles << "Employee Role" if person.active_employee_roles.present?
      person_roles << "Consumer Role" if person.is_consumer_role_active?
      person_roles << "Resident Role" if person.is_resident_role_active?
      person_roles << "Hbx Staff Role" if person.hbx_staff_role.present?
      person_roles << "Assister Role" if person.assister_role.present?
      person_roles << "CSR Role" if person.csr_role.present?
      person_roles << "POC" if person.employer_staff_roles.present?
      person_roles << "Broker Agency Staff Role" if person.broker_agency_staff_roles.present?
      person_roles << "General Agency Staff Role" if person.general_agency_staff_roles.present?
      person_roles
    end

    def employee_eligibility_status(enrollment)
      enrollment.benefit_group_assignment.census_employee.aasm_state.camelcase if enrollment.is_shop? && enrollment.benefit_group_assignment.present? && enrollment.benefit_group_assignment.census_employee.can_be_reinstated?
    end

    def get_person_roles(person, person_roles = [])
      person_roles << "Employee Role" if person.active_employee_roles.present?
      person_roles << "Consumer Role" if person.is_consumer_role_active?
      person_roles << "Resident Role" if person.is_resident_role_active?
      person_roles << "Hbx Staff Role" if person.hbx_staff_role.present?
      person_roles << "Assister Role" if person.assister_role.present?
      person_roles << "CSR Role" if person.csr_role.present?
      person_roles << "POC" if person.employer_staff_roles.present?
      person_roles << "Broker Agency Staff Role" if person.broker_agency_staff_roles.present?
      person_roles << "General Agency Staff Role" if person.general_agency_staff_roles.present?
      person_roles
    end
  end
end
