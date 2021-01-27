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
      if enrollment.is_shop? && enrollment.benefit_group_assignment.present?
        if enrollment.benefit_group_assignment.census_employee.can_be_reinstated?
          enrollment.benefit_group_assignment.census_employee.aasm_state.camelcase
        end
      end
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

    def render_configuration_navigation_menu(options = {})

      options = {namespace_options: {include_no_features_defined: false}}

      # graph = EnrollRegistry[:feature_graph]

      root_paths = [
        [:features],
        [:enroll_app, :aca_shop_market],
        [:enroll_app, :fehb_market]
      ]

      # vertices = root_paths.collect{|path| graph.vertices.detect{|v| v.path == path}}
      # options = {namespace_options: {starting_namespaces: vertices}}


      # graph = EnrollRegistry[:feature_graph]
      # options = {namespace_options: {include_no_features_defined: false, starting_namespaces: [graph.vertices[2], graph.vertices[3]]}}


      nav = EnrollRegistry.navigation(options)
      nav.render_html
    end
  end
end
