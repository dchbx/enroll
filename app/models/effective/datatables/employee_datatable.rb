module Effective
  module Datatables
    class EmployeeDatatable < Effective::MongoidDatatable
      include Config::AcaModelConcern

      datatable do

        bulk_actions_column do
          bulk_action 'Employee will enroll',  change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection=>"enroll"), data: {confirm: 'These employees will be used to estimate your group size and participation rate', no_turbolink: true}
          bulk_action 'Employee will not enroll with valid waiver', change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection=>"waive"), data: {confirm: 'Remember, your group size can affect your premium rates', no_turbolink: true}
          bulk_action 'Employee will not enroll with invalid waiver', change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection=>"will_not_participate"), data: {confirm: 'Remember, your participation rate can affect your group premium rates', no_turbolink: true}
        end

        table_column :employee_name, :width => '50px', :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          (link_to row.full_name, employers_employer_profile_census_employee_path(@employer_profile.id, row.id, tab: 'employees')) + raw("<br>")
        }, :sortable => false, :filter => false

        table_column :dob, :label => 'DOB', :proc => Proc.new { |row|
          row.dob
        }, :sortable => false, :filter => false

        table_column :hired_on, :proc => Proc.new { |row|
          row.hired_on
        }, :sortable => false, :filter => false

        table_column :terminated_on, :proc => Proc.new { |row|
          row.employment_terminated_on || "Active"
        }, :sortable => false, :filter => false, :visible => true

        table_column :status, :proc => Proc.new { |row|
          employee_state_format(row.aasm_state, row.employment_terminated_on)
        }, :sortable => false, :filter => false

        table_column :benefit_package, :proc => Proc.new { |row|
          row.active_benefit_group_assignment.benefit_group.title.capitalize if row.active_benefit_group_assignment.present?
        }, :sortable => false, :filter => false

        if attributes["renewal"]
          table_column :renewal_benefit_package, :label => 'Renewal Benefit Package', :proc => Proc.new { |row|
            row.renewal_benefit_group_assignment.benefit_group.title.capitalize if row.active_benefit_group_assignment.present?
          }, :filter => false, :sortable => false
        end

        table_column :enrollment_status, :proc => Proc.new { |row|
            enrollment_state(row)
        }, :sortable => false, :filter => false

        if attributes["renewal_status"]
          table_column :renewal_enrollment_status, :proc => Proc.new { |row|
            renewal_enrollment_state(row)
          }, :filter => false, :sortable => false
        end

        unless individual_market_is_enabled?
          table_column :est_participation, :proc => Proc.new { |row|
             row.expected_selection.titleize if row.expected_selection
          }, :sortable => false, :filter => false
        end

        table_column :actions, label: "", :width => '50px', :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          # Has to specify the valid route path for rehire and initiate cobra
          dropdown = [
              # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
              ['Edit', edit_employers_employer_profile_census_employee_path(@employer_profile, row.id, tab: 'employees'), 'static'],
              ['Terminate', confirm_effective_date_employers_employer_profile_census_employees_path(@employer_profile, census_employee_id: row.id, census_employee: row.id, type: 'terminate', tab: 'employees'), terminate_possible?(row)],
              ['Rehire', confirm_effective_date_employers_employer_profile_census_employees_path(@employer_profile, census_employee_id: row.id, census_employee: row.id, type: 'rehire', tab: 'employees'), rehire_possible?(row)],
              ['Initiate Cobra', confirm_effective_date_employers_employer_profile_census_employees_path(@employer_profile, census_employee_id: row.id, type: 'cobra'), cobra_possible?(row)]
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "census_employeeid_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        unless  (defined? @employees) && @employees.present?   #memoize the wrapper class to persist @search_string
          @employees = Queries::EmployeeDatatableQuery.new(attributes)
        end
        @employees
      end

      def cobra_possible? census_employee
        return 'disabled' if census_employee.cobra_linked?
        return 'disabled' if census_employee.cobra_eligible?
        return 'disabled' if census_employee.rehired?
        census_employee.active_or_pending_termination? ? 'ajax' : 'disabled'
      end

      def rehire_possible? census_employee
        return 'disabled' if census_employee.cobra_linked?
        return 'disabled' if census_employee.cobra_eligible?
        return 'disabled' if census_employee.rehired?
        census_employee.active_or_pending_termination? ? 'ajax' : 'disabled'
      end

      def terminate_possible? census_employee
        census_employee.active_or_pending_termination? ? 'disabled' : 'ajax'
      end

      def nested_filter_definition
          {
            employers:
                [
                    {scope: 'active_alone', label: 'Active only'},
                    {scope: 'active', label: 'Active & COBRA'},
                    {scope: 'by_cobra', label: 'COBRA only'},
                    {scope: 'terminated', label: 'Terminated'},
                    {scope: 'all', label: 'All'}
                ],
            top_scope: :employers
        }
      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
      end

    end
  end
end
