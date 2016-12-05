
module Effective
  module Datatables
    class PremiumBillingReportDataTable < Effective::MongoidDatatable
     include Employers::PremiumStatementHelper
     include Pundit


     datatable do
      array_column :full_name,:label => 'Employee Profile',
      :proc => Proc.new { |row| 
        content_tag(:span, class: 'name') do
          row.employee_role.person.full_name.try(:titleize)
        end +
        content_tag(:span, 
          content_tag(:p, "DOB: #{format_date row.employee_role.person.dob}")
          ) +
        content_tag(:span, 
          content_tag(:p, "SSN: #{number_to_obscured_ssn row.employee_role.person.ssn}")
          ) +
        content_tag(:span, 
         "HIRED:  #{format_date row.employee_role.census_employee.hired_on}"
         )
        }, :filter => false, :sortable => false

        array_column :title ,:label => 'Benefit Package',
        :proc => Proc.new { |row|
          content_tag(:span, class: 'benefit-group') do
            row.benefit_group.title.try(:titleize)
          end
          },:filter => false, :sortable => false  


          array_column :coverage_kind,:label => 'Insurance Coverage',
          :proc => Proc.new { |row| 
            content_tag(:span) do
              content_tag(:span, class: 'name') do
                mixed_case(row.coverage_kind) 
              end +
              content_tag(:span) do
                " | # Covered: ".to_s + row.humanized_dependent_summary.to_s 
              end +  
              content_tag(:p, 
                (row.plan.carrier_profile.legal_name.to_s + " -- " + row.plan.name.to_s)
                )  
            end
            }, :filter => false, :sortable => false

            
            array_column :cost,:label => 'COST',
            :proc => Proc.new { |row| 
             content_tag(:span, 
               "Employer Contribution: ".to_s + (number_to_currency row.total_employer_contribution.to_s)
               ) +
             content_tag(:div) do
               "Employee Contribution:".to_s + (number_to_currency number_to_currency row.total_employee_cost)
             end  + content_tag(:p,  content_tag(:strong, "Total:") +  content_tag(:strong, row.total_premium))
             }, :filter => false, :sortable => false

           end




           def collection
            @employer_profile = EmployerProfile.find(attributes[:id])
            billing_date = attributes[:billing_date]
            @hbx_enrollments = @employer_profile.enrollments_for_billing(billing_date)
          end

          def global_search?
            false
          end

        end
      end
    end
