
module Effective
  module Datatables
    class FamilyDataTable < Effective::MongoidDatatable
      datatable do
        bulk_actions_column do
           #bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { method: :post, confirm: 'Generate Invoices?' }
        end

        #table_column :family_hbx_id, :proc => Proc.new { |row| row.hbx_assigned_id }, :filter => false, :sql_column => "hbx_id"

        table_column :name, :proc => Proc.new { |row| link_to row.primary_applicant.person.full_name, resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id)}, :filter => false, :sortable => false
        table_column :ssn, :proc => Proc.new { |row| truncate(number_to_obscured_ssn(row.primary_applicant.person.ssn)) }, :filter => false, :sortable => false
        table_column :dob, :proc => Proc.new { |row| format_date(row.primary_applicant.person.dob)}, :filter => false, :sortable => false
        table_column :hbx_id, :proc => Proc.new { |row| row.primary_applicant.person.hbx_id }, :filter => false, :sortable => false
        table_column :count, :width => '100px', :proc => Proc.new { |row| row.active_family_members.size }, :filter => false, :sortable => false
        table_column :registered?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.user.present? ? "Yes" : "No"} , :filter => false, :sortable => false
        table_column :consumer?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.consumer_role.present?  ? "Yes" : "No"}, :filter => false, :sortable => false
        table_column :employee?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.active_employee_roles.present?  ? "Yes" : "No"}, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
           ['Add SEP', add_sep_form_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax'],
           ['View SEP History', show_sep_history_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax'],
           ['Cancel Enrollment', cancel_enrollment_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), cancel_enrollment_type(row)],
           ['Terminate Enrollment', terminate_enrollment_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), terminate_enrollment_type(row)],
           ['Edit DOB / SSN', edit_dob_ssn_path(id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax'],
           ['Send Secure Message', new_insured_inbox_path(id: row.primary_applicant.person.id, profile_id: current_user.person.hbx_staff_role.hbx_profile.id, to: row.primary_applicant.person.last_name + ', ' + row.primary_applicant.person.first_name, family_actions_id: "family_actions_#{row.id.to_s}"), secure_message_link_type(row, current_user)],
           ['EDIT APTC / CSR', edit_aptc_csr_path(family_id: row.id, person_id: row.primary_applicant.person.id), aptc_csr_link_type(row)],
           ['Collapse Form', hide_form_exchanges_hbx_profiles_path(family_id: row.id, person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id.to_s}"),'ajax']
          ]
          render '/datatables/shared/dropdown', dropdowns: dropdown, row_actions_id: "family_actions_#{row.id.to_s}"
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

      def aptc_csr_link_type(family)
        family.active_household.latest_active_tax_household.present? ? 'ajax' : 'disabled'
      end

      def cancel_enrollment_type(family)
        hbx_enrollment = family.households.first.hbx_enrollments.last
        hbx_enrollment.nil? ? 'disabled' : (hbx_enrollment.coverage_selected? ? 'ajax' : 'disabled')
      end

      def terminate_enrollment_type(family)
        hbx_enrollment = family.households.first.hbx_enrollments.last
        hbx_enrollment.nil? ? 'disabled' : (hbx_enrollment.coverage_selected? ? 'ajax' : 'disabled')
      end

      def edit_dob_link_type(current_user)
        (current_user.roles.include? "hbx_staff" and Permission.where(name: 'hbx_staff').first.can_update_ssn?) ? 'ajax' : 'disabled'

      end

      def nested_filter_definition
        {
        employer_options: [
          {scope: 'all', label: 'All'},
          {scope: 'enrolled', label: 'Enrolled'},
          {scope: 'by_enrollment_renewing', label: 'Renewing'},
          {scope: 'waived', label: 'Waived'},
          {scope: 'sep_eligible', label: 'SEP Eligible'}
        ],
        coverall_options: [
          {scope: 'all', label: 'All'},
          {scope: 'sep_eligible', label: 'SEP Eligible'}
        ],
        individual_options: [
          {scope: 'all', label: 'All'},
          {scope: 'all_assistance_receiving', label: 'Assisted'},
          {scope: 'all_unassisted', label: 'Unassisted'},
          {scope: 'sep_eligible', label: 'SEP Eligible'}
        ],
        families: [
          {scope: 'all', label: 'All'},
          {scope: 'by_enrollment_individual_market', label: 'Individual Enrolled', subfilter: :individual_options},
          {scope: 'by_enrollment_shop_market', label: 'Employer Sponsored Coverage Enrolled', subfilter: :employer_options},
          {scope: 'by_enrollment_coverall', label: 'Cover All', subfilter: :coverall_options},
          {scope: 'non_enrolled', label: 'Non Enrolled'},
        ],
        top_scope: :families
        }
      end
    end
  end
end
