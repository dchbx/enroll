module Effective
  module Datatables
    class PlanDesignEmployeeDatatable < ::Effective::MongoidDatatable
      include Config::AcaModelConcern

      datatable do

        bulk_actions_column do
          bulk_action 'Employee will enroll',  expected_selection_plan_design_proposal_plan_design_census_employees_path(@plan_design_proposal.proposal, :expected_selection=>"enroll"), data: {confirm: 'These employees will be used to estimate your group size and participation rate', no_turbolink: true}
          bulk_action 'Employee will not enroll with valid waiver', expected_selection_plan_design_proposal_plan_design_census_employees_path(@plan_design_proposal.proposal, :expected_selection=>"waive"), data: {confirm: 'Remember, your group size can affect your premium rates', no_turbolink: true}
          bulk_action 'Employee will not enroll with invalid waiver', expected_selection_plan_design_proposal_plan_design_census_employees_path(@plan_design_proposal.proposal, :expected_selection=>"will_not_participate"), data: {confirm: 'Remember, your participation rate can affect your group premium rates', no_turbolink: true}
        end

        table_column :employee_name, :width => '50px', :proc => Proc.new { |row|
          # @employer_profile = row.employer_profile
          # (link_to row.full_name, employers_employer_profile_census_employee_path(@employer_profile.id, row.id)) + raw("<br>")
          row.full_name
        }, :sortable => false, :filter => false

        table_column :dob, :label => 'DOB', :proc => Proc.new { |row|
          row.dob.strftime("%m/%d/%Y")
        }, :sortable => false, :filter => false

        table_column :hired_on, :proc => Proc.new { |row|
          row.hired_on
        }, :sortable => false, :filter => false

        table_column :status, :proc => Proc.new { |row|
          row.aasm_state.titleize
        }, :sortable => false, :filter => false
        
        unless individual_market_is_enabled?
          table_column :est_participation, :proc => Proc.new { |row|
            row.expected_selection.titleize if row.expected_selection
          }, :sortable => false, :filter => false
        end

        table_column :actions, label: "", :width => '50px', :proc => Proc.new { |row|
          # @employer_profile = row.employer_profile

          proposal = row.plan_design_proposal
          # Has to specify the valid route path for rehire and initiate cobra
          dropdown = [
              ['Edit', sponsored_benefits.edit_plan_design_proposal_plan_design_census_employee_path(proposal, row), 'ajax'],
              ['Delete', sponsored_benefits.plan_design_proposal_plan_design_census_employee_path(proposal, row), 'delete ajax with confirm and elementId', "Do you want to delete this employee?", "plan_design_employee_delete"],
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "plan_design_employee_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        unless  (defined? @employees) && @employees.present?   #memoize the wrapper class to persist @search_string
          @employees = Queries::PlanDesignEmployeeQuery.new(attributes)
        end
        @employees
      end

      # def cobra_possible? census_employee
      #   return 'disabled' if census_employee.cobra_linked?
      #   return 'disabled' if census_employee.cobra_eligible?
      #   return 'disabled' if census_employee.rehired?
      #   census_employee.active_or_pending_termination? ? 'ajax' : 'disabled'
      # end

      # def rehire_possible? census_employee
      #   return 'disabled' if census_employee.cobra_linked?
      #   return 'disabled' if census_employee.cobra_eligible?
      #   return 'disabled' if census_employee.rehired?
      #   census_employee.active_or_pending_termination? ? 'ajax' : 'disabled'
      # end

      # def terminate_possible? census_employee
      #   census_employee.active_or_pending_termination? ? 'disabled' : 'ajax'
      # end

      def nested_filter_definition
          {
            employees:
                [
                    {scope: 'active_alone', label: 'Active only'},
                    {scope: 'active', label: 'Active & COBRA'},
                    {scope: 'by_cobra', label: 'COBRA only'},
                    # {scope: 'terminated', label: 'Terminated'},
                    {scope: 'all', label: 'All'}
                ],
            top_scope: :employees
        }
      end
    end
  end
end
