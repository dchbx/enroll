module Effective
  module Datatables
    class BenefitSponsorsCoverageReportsDataTable < Effective::MongoidDatatable
      attr_accessor :product_info, :issuer_info
      datatable do
        table_column :full_name, label: "Employee Profile",
          :proc => Proc.new { |row|
            @sponsored_benefit = row.primary_member.sponsored_benefit
            primary_member = row.primary_member
            member_info = primary_member.member_info
            content_tag(:span) do
            format_name(
              first_name: member_info.first_name,
              last_name: member_info.last_name,
              middle_name: member_info.middle_name,
              name_sfx: member_info.suffix
            )
          end +
          content_tag(:span, content_tag(:p, "DOB: #{format_date primary_member.dob}")) +
          content_tag(:span, content_tag(:p, "SSN: #{number_to_obscured_ssn member_info.ssn}")) +
          content_tag(:span, "HIRED:  #{format_date primary_member.employee_role.hired_on}")
          }, :filter => false, :sortable => false
        
        table_column :title, :label => 'Benefit Package',
          :proc => Proc.new { |row|
            content_tag(:span, class: 'benefit-group') do
              @sponsored_benefit.benefit_package.title.to_s.humanize
            end
          }, :filter => false, :sortable => false

        table_column :coverage_kind,:label => 'Insurance Coverage',
        :proc => Proc.new { |row|
          content_tag(:span) do
            content_tag(:span, class: 'name') do
              mixed_case(@sponsored_benefit.product_kind.to_s.humanize)
            end +
            content_tag(:span) do
              " | # Dep(s) Covered: ".to_s + (row.members.size - 1).to_s
            end +
            content_tag(:p, (issuer_info[row.group_enrollment.product[:issuer_profile_id]] + " -- " + product_info[row.group_enrollment.product[:id]]))
          end
        }, :filter => false, :sortable => false

        table_column :cost,:label => 'COST',
        :proc => Proc.new { |row|
          content_tag(:span, "Employer Contribution: ".to_s + (number_to_currency row.group_enrollment.sponsor_contribution_total.to_s)) +
          content_tag(:div) do 
            "Employee Contribution:".to_s + (number_to_currency (row.group_enrollment.product_cost_total.to_f - row.group_enrollment.sponsor_contribution_total.to_f).to_s) 
          end  +
          content_tag(:p,  content_tag(:strong, "Total:") +  content_tag(:strong, row.group_enrollment.product_cost_total.to_s))
        }, :filter => false, :sortable => false
      end


      def collection
        return @collection if defined? @collection
        @employer_profile = BenefitSponsors::Organizations::Profile.find(attributes[:id])
        return BenefitSponsors::LegacyCoverageReportAdapter.new([]) if @employer_profile.nil?
        query = BenefitSponsors::Queries::CoverageReportsQuery.new(@employer_profile, attributes[:billing_date])
        @products_hash ||= load_products
        @collection = query.execute
      end

      def global_search?
        true
      end

      def load_products
        current_year = TimeKeeper.date_of_record.year
        previous_year = current_year - 1
        next_year = current_year + 1

        plans = BenefitMarkets::Products::Product.aca_shop_market.by_state(Settings.aca.state_abbreviation)

        current_possible_plans = plans.where(:"application_period.min".in =>[
          Date.new(previous_year, 1, 1),
          Date.new(current_year, 1, 1),
          Date.new(next_year, 1, 1)
        ])

        @product_info = current_possible_plans.inject({}) do |result, product|
          result[product.id] = product.title
          result
        end

        @issuer_info = current_possible_plans.map(&:issuer_profile).uniq.inject({}) do |result, issuer|
          result[issuer.id] = issuer.legal_name
          result
        end
      end
    end
  end
end
