module Effective
  module Datatables
    class CensusEmployeeDatatable < Effective::MongoidDatatable

      datatable do
        #default_order :full_name, :asc
        default_entries 10
        #table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| row.fein }, :sortable => false, :filter => false
        table_column :full_name, :label => 'Full Name', :width =>'100px',:proc => Proc.new { |row| row.full_name },  :sortable => true,:filter => false
        table_column :dob,:label => 'Date of Birth',:width =>'100px',:proc => Proc.new { |row| row.dob },:sortable => false, :filter => false
        table_column :aasm_state,:label => 'Status',:width => '100px',:proc => Proc.new { |row| employee_state_format(row.aasm_state, row.employment_terminated_on)},:sortable => true,:filter => false
        table_column :hired_on,:label => 'Hired on',:width => '100px',:proc => Proc.new { |row| row.hired_on },:sortable => true,:filter => false
        table_column :benefit_package, :label=> "Benefit Package", :width => '100px',:proc=>Proc.new{|row| row.active_benefit_group_assignment.benefit_group.title.capitalize},:sortable=>true,:filter=>false

        if  !attributes[:current_employer_profile].nil? && attributes[:current_employer_profile].renewing_plan_year.present?
          table_column :renewal_benefit_package do |row|
            renew_benefit_group(row)
          end
        end

        table_column :termination, :label=>"Termination Date", :width => '100px', :proc => Proc.new { |row| row.aasm_state if ['terminated', 'all'].include?(row.aasm_state) }, :filter => false, :sortable => false
        table_column :enrollment_status, :label=>"Enrollment Status",:width => '100px', :proc => Proc.new { |row| enrollment_state(row) }, :filter => false, :sortable => false

        if !attributes[:current_employer_profile].nil? && attributes[:current_employer_profile].renewing_published_plan_year.present?
           table_column :renewal_enrollment_status, :label=>"Renewal Enrollment Status"
        end
        table_column :action do |row|
          edit(row)
          terminate(row)

        end


      #
      #   <td>
      #   <%= link_to name_to_listing(census_employee), employers_employer_profile_census_employee_path(@employer_profile.id, census_employee.id, status: status) %>
      #     </td>
      #     <td><%= format_date census_employee.dob %></td>
      #
      #   </td>
      #     <% if @employer_profile.renewing_plan_year.present? %>
      #
      #     </td>
      #   <% end %>
      # <% if ['terminated', 'all'].include?(status) %>
      # <td><%= format_date census_employee.employment_terminated_on %>
      #     </td>
      #     <% end %>
      #     <td><%= enrollment_state(census_employee) %></td>
      #     <% if @employer_profile.renewing_published_plan_year.present? %>
      #         <td><%= renewal_enrollment_state(census_employee) %></td>
      # <% end %>
      # <td class="table-functions">
      # <% if census_employee.employment_terminated? %>
      #       <a class="show_confirm btn btn-green-2" id="show_confirm_#{census_employee.id} <%= pundit_class EmployerProfile, :updateable? %>">
      #         <span class="hidden-xs hidden-sm visible-md visible-lg" style="margin-left: -10px;" onclick="$(this).closest('tr').next().show();">Rehire</span>
      #       </a>
      #     <% else %>
      #     <%= link_to raw('<i class="fa fa-pencil fa-lg pull-right" data-toggle="tooltip" title="Edit"></i>'), employers_employer_profile_census_employee_path(@employer_profile.id, census_employee.id, status: status, tab: 'employees') %>
      #       <i class="fa fa-trash-o fa-lg pull-right" data-toggle="tooltip" title="Terminate"></i>
      #     <% end %>
      #     </td>




      end

      def renew_benefit_group(row)
        if row.renewal_benefit_group_assignment.present?
          row.renewal_benefit_group_assignment.benefit_group.title.capitalize
        end
      end
      def edit(row)

      end
      def terminate(row)
        if row.employment_terminated?

        else
          #link_to raw('<i class="fa fa-pencil fa-lg pull-right" data-toggle="tooltip" title="Edit"></i>'), employers_employer_profile_census_employee_path(@employer_profile.id, census_employee.id, status: census_employee.aasm_state, tab: 'employees')
        end
      end

      def collection
        @census_employee = CensusEmployee.where(employer_profile_id: attributes[:current_employer_profile_id])
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