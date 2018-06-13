
module Effective
  module Datatables
    class FamilyDataTable < Effective::MongoidDatatable
      include Config::AcaModelConcern
      datatable do
        #table_column :family_hbx_id, :proc => Proc.new { |row| row.hbx_assigned_id }, :filter => false, :sql_column => "hbx_id"
        table_column :name, :label => 'Name', :proc => Proc.new { |row| link_to row.primary_applicant.person.full_name, resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id)}, :filter => false, :sortable => false
        table_column :ssn, :label => 'SSN', :proc => Proc.new { |row| truncate(number_to_obscured_ssn(row.primary_applicant.person.ssn)) }, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => Proc.new { |row| format_date(row.primary_applicant.person.dob)}, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| row.primary_applicant.person.hbx_id }, :filter => false, :sortable => false
        table_column :count, :label => 'Count', :width => '100px', :proc => Proc.new { |row| row.active_family_members.size }, :filter => false, :sortable => false
        table_column :active_enrollments, :label => 'Active Enrollments?', :proc => Proc.new { |row| row.active_household.hbx_enrollments.active.enrolled_and_renewing.present? ? "Yes" : "No"}, :filter => false, :sortable => false
        table_column :registered?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.user.present? ? "Yes" : "No"} , :filter => false, :sortable => false
        if individual_market_is_enabled?
          table_column :consumer?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.consumer_role.present?  ? "Yes" : "No"}, :filter => false, :sortable => false
        end
        table_column :employee?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.active_employee_roles.present?  ? "Yes" : "No"}, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
           ['Add SEP', add_sep_form_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), individual_market_is_enabled? ? add_sep_link_type( pundit_allow(HbxProfile, :can_add_sep?) ) : 'disabled' ],
           ['View SEP History', show_sep_history_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax'],
           ['Cancel Enrollment', cancel_enrollment_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), individual_market_is_enabled? ? cancel_enrollment_type(row, pundit_allow(Family, :can_update_ssn?)) : 'disabled'],
           #cancel_enrollment_type(row, pundit_allow(Family, :can_update_ssn?))],
           ['Terminate Enrollment', terminate_enrollment_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), individual_market_is_enabled? ? terminate_enrollment_type(row, pundit_allow(Family, :can_update_ssn?)) : 'disabled'],
           #terminate_enrollment_type(row, pundit_allow(Family, :can_update_ssn?))],
           [("<div class='" + pundit_class(Family, :can_update_ssn?) + "'> Edit DOB / SSN </div>").html_safe, edit_dob_ssn_path(id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax'],
           ['Send Secure Message', new_insured_inbox_path(id: row.primary_applicant.person.id, profile_id: current_user.person.hbx_staff_role.hbx_profile.id, to: row.primary_applicant.person.last_name + ', ' + row.primary_applicant.person.first_name, family_actions_id: "family_actions_#{row.id.to_s}"), secure_message_link_type(row, current_user)],
           ['View Username and Email', get_user_info_exchanges_hbx_profiles_path(person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id.to_s}"), (individual_market_is_enabled? && pundit_allow(Family, :can_view_username_and_email?)) ? 'ajax' : 'disabled'],
           ['Collapse Form', hide_form_exchanges_hbx_profiles_path(family_id: row.id, person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id.to_s}"),'ajax']
           ]
           if individual_market_is_enabled?
              dropdown += [
                ['Edit APTC / CSR', edit_aptc_csr_path(family_id: row.id, person_id: row.primary_applicant.person.id), aptc_csr_link_type(row, pundit_allow(Family, :can_update_ssn?))],
                ['Paper', resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id, original_application_type: 'paper'), 'static'],
              ]
           end
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "family_actions_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      scopes do
         scope :legal_name, "Hello"
      end

      def collection
        unless  (defined? @families) && @families.present?   #memoize the wrapper class to persist @search_string
          @families = Queries::FamilyDatatableQuery.new(attributes)
        end
        @families
      end

      def global_search?
        true
      end

      def secure_message_link_type(family, current_user)
        person = family.primary_applicant.person
        ((person.user.present? || person.emails.present?) && current_user.person.hbx_staff_role) ? 'ajax' : 'disabled'
      end

      def aptc_csr_link_type(family, allow)
        # return "disabled" # DISABLING APTC FEATURE.
        family.active_household.latest_active_tax_household.present? && allow ? 'ajax' : 'disabled'
      end

      def add_sep_link_type(allow)
        allow ? 'ajax' : 'disabled'
      end

      def cancel_enrollment_type(family, allow)
        (family.all_enrollments.cancel_eligible.present? && allow) ? 'ajax' : 'disabled'
      end

      def terminate_enrollment_type(family, allow)
        (family.all_enrollments.can_terminate.present? && allow) ? 'ajax' : 'disabled'
      end

      def nested_filter_definition
        families_tab = [
          {scope: 'all', label: 'All'},
          {scope: 'by_enrollment_shop_market', label: 'Employer Sponsored Coverage Enrolled', subfilter: :employer_options},
          {scope: 'non_enrolled', label: 'Non Enrolled'}
        ]
        if individual_market_is_enabled?
         families_tab.insert(1, {scope: 'by_enrollment_individual_market', label: 'Individual Enrolled', subfilter: :individual_options})
        end

        {
        employer_options: [
          {scope: 'all', label: 'All'},
          {scope: 'enrolled', label: 'Enrolled'},
          {scope: 'by_enrollment_renewing', label: 'Renewing'},
          {scope: 'waived', label: 'Waived'},
          {scope: 'sep_eligible', label: 'SEP Eligible'}
        ],
        individual_options: [
          {scope: 'all', label: 'All'},
          {scope: 'all_assistance_receiving', label: 'Assisted'},
          {scope: 'all_unassisted', label: 'Unassisted'},
          {scope: 'sep_eligible', label: 'SEP Eligible'}
        ],
        families: families_tab,
        top_scope: :families
        }
      end
    end
  end
end
