module Effective
  module Datatables
    class PremiumBillingReportDataTable < Effective::ArraycolumnDatatable
     include Employers::PremiumStatementHelper
     include Pundit


     datatable do
      array_column :full_name,:label => 'Employee Profile', premium_report: true,
      :proc => Proc.new { |row|
        content_tag(:span, class: 'hide') do
          row.employee_role.person.last_name
        end +
        content_tag(:span, class: 'name') do
          name_to_listing(row.employee_role.person)
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

        table_column :title ,:label => 'Benefit Package',
        :proc => Proc.new { |row|
          content_tag(:span, class: 'benefit-group') do
            row.benefit_group.title.try(:titleize)
          end
          },:filter => false, :sortable => false


          table_column :coverage_kind,:label => 'Insurance Coverage',
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

            table_column :cost,:label => 'COST',
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
             @billing_date = (attributes[:billing_date].is_a? Date) ? attributes[:billing_date] : Date.strptime(attributes[:billing_date], "%m/%d/%Y")
             query = Queries::EmployerPremiumStatement.new(@employer_profile, @billing_date)
             @hbx_enrollments =  query.execute.nil? ? [] : query.execute.hbx_enrollments
           end

           def global_search?
            true
          end

          def nested_filter_definition
            {
              employer_options: [
                {scope: 'all', label: 'All'}
                ],
                top_scope: :employer_options
              }
            end

          end
        end
      end
