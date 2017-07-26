module Effective
  module Datatables
    class PremiumBillingReportDataTable < Effective::MongoidDatatable
      include Employers::PremiumStatementHelper
      include Pundit
      attr_reader :hbx_cache, :hbx_enrollment_ids

      datatable do
        table_column :full_name,:label => 'Employee Profile',
        :proc => Proc.new { |row|
          hbx = row[1]
          content_tag(:span, class: 'name') do
            name_to_listing(hbx.employee_role.person)
          end +
          content_tag(:span, content_tag(:p, "DOB: #{format_date hbx.employee_role.person.dob}")) +
          content_tag(:span, content_tag(:p, "SSN: #{number_to_obscured_ssn hbx.employee_role.person.ssn}")) +
          content_tag(:span, "HIRED:  #{format_date hbx.employee_role.census_employee.hired_on}")
        }, :filter => false, :sortable => false

        table_column :title ,:label => 'Benefit Package',
        :proc => Proc.new { |row|
          hbx = row[1]
          content_tag(:span, class: 'benefit-group') do
            hbx.benefit_group.title.try(:titleize)
          end
        }, :filter => false, :sortable => false

        table_column :coverage_kind,:label => 'Insurance Coverage',
        :proc => Proc.new { |row|
          hbx = row[1]
          content_tag(:span) do
            content_tag(:span, class: 'name') do
              mixed_case(hbx.coverage_kind)
            end +
            content_tag(:span) do
              " | # Dep(s) Covered: ".to_s + hbx.humanized_dependent_summary.to_s
            end +
            content_tag(:p, (hbx.plan.carrier_profile.legal_name.to_s + " -- " + hbx.plan.name.to_s))
          end
        }, :filter => false, :sortable => false

        table_column :cost,:label => 'COST',
        :proc => Proc.new { |row|
          hbx = row[1]
          content_tag(:span, "Employer Contribution: ".to_s + (number_to_currency hbx.total_employer_contribution.to_s)) +
          content_tag(:div) do 
            "Employee Contribution:".to_s + (number_to_currency number_to_currency hbx.total_employee_cost) 
          end  +
          content_tag(:p,  content_tag(:strong, "Total:") +  content_tag(:strong, hbx.total_premium))
        }, :filter => false, :sortable => false
      end

      def collection
        @collection ||= Queries::PremiumBillingReportQuery.new(hbx_enrollment_ids)
      end

      def global_search?
        true
      end

      # Override the callback to allow caching of sub-queries
      def arrayize(collection)
        return collection if @already_ran_caching
        @already_ran_caching = true
        @hbx_cache = {}
        hbx_enrollment_ids = @hbx_enrollment_ids
        collection.each do |fam|
          fam.households.each do |h|
            h.hbx_enrollments.each{|hbx| @hbx_cache[hbx.id] =  hbx if @hbx_enrollment_ids.include?(hbx.id)}.compact
          end
        end
        super(@hbx_cache)
      end

      def hbx_enrollment_ids
        @billing_date = (attributes[:billing_date].is_a? Date) ? attributes[:billing_date] : Date.strptime(attributes[:billing_date], "%m/%d/%Y")
        @employer_profile = EmployerProfile.find(attributes[:id])
        query = Queries::EmployerPremiumStatement.new(@employer_profile, @billing_date)
        @hbx_enrollment_ids ||=  query.execute.nil? ? [] : query.execute.hbx_enrollments.collect{|h| h._id}
      end

      def nested_filter_definition
        {
        families: [
          {scope: 'all', label: 'All'}
        ],
        top_scope: :families
        }
      end
                     
    end
  end
end