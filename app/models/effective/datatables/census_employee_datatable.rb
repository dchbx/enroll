module Effective
  module Datatables
    class CensusEmployeeDatatable < Effective::MongoidDatatable
      datatable do
        default_order :full_name, :asc
        default_entries 10
        table_column :full_name, :label => 'Full Name',:width => '100px', :proc => Proc.new { |row| row.full_name }, :filter => false, :sortable => false
        table_column :dob,:label => 'Date of Birth',:width => '100px'
        table_column :aasm_state,:label => 'Status',:width => '100px'
        table_column :hired_on,:label => 'Hired on',:width => '100px'

        table_column :edit do
          #edit
        end
        table_column :terminted  do |census_employee|

          if census_employee.employment_terminated?
              census_employee.first_name
          else
             census_employee.last_name
            link_to raw('<i class="fa fa-pencil fa-lg pull-right" data-toggle="tooltip" title="Edit"></i>'), employers_employer_profile_census_employee_path(@employer_profile.id, census_employee.id, status: census_employee.aasm_state, tab: 'employees')

          end

        end

        # table_column #benefit package
        # table_column #enrollment status
        # table_column  :label => 'terminated',:width => '100px'
        # table_column  :label => 'edit',:width => '100px'


      #   <th>Employee Name<!-- <i class="fa fa-caret-down"></i>--></th>
      #   <th>DOB</th>
      #     <th>Hired</th>
      #   <th>Status</th>
      #     <th>Benefit Package</th>
      #   <% if @employer_profile.renewing_plan_year.present? %>
      #     <th>Renewal Benefit Package</th>
      #     <% end %>
      #     <% if ['terminated', 'all'].include?(status) %>
      #     <th>Termination Date</th>
      #   <% end %>
      #   <th>Enrollment Status</th>
      #     <% if @employer_profile.renewing_published_plan_year.present? %>
      #         <th>Renewal Enrollment Status</th>
      #   <% end %>
      # <th>
      # &nbsp;
      # </th>
      end

      def collection
        @census_employee = CensusEmployee.all
      end

      scopes do
        scope :legal_name, "Hello"
      end


      def global_search?
        true
      end

    end
  end
end