require "rails_helper"

module BenefitSponsors
  RSpec.describe ContributionCalculators::CcaShopReferencePlanContributionCalculator do
    let(:contribution_calculator) do
      ::BenefitSponsors::ContributionCalculators::CcaShopReferencePlanContributionCalculator.new
    end

    let(:contribution_model) do
      instance_double(
        ::BenefitMarkets::ContributionModels::ContributionModel,
        :contribution_units => contribution_units
      )
    end

    let(:product) { double }

    let(:group_size) { 1 }
    let(:sic_code) { "a sic code" }

    describe "given:
    - a relationship based pricing model
    - with an 'employee' group
    - with a 'spouse' group
    - with a 'dependent' group" do

      let(:contribution_units) do
        [
          employee_contribution_unit,
          spouse_contribution_unit,
          dependent_contribution_unit,
        ]
      end

      let(:employee_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit,
          name: "employee",
          id: "employee_cu_id"
        )
      end

      let(:spouse_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit,
          name: "spouse",
          id: "spouse_cu_id"
        )
      end

      let(:dependent_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit,
          name: "dependent",
          id: "dependent_cu_id"
        )
      end

      describe "with a pricing determination and one family that has:
        - an employee
        - a spouse
        - a child
      " do

        let(:employee_dob) { Date.new(1990, 6, 1) }
        let(:employee_member_id) { "some_employee_id" }

        let(:employee) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: employee_member_id,
            relationship: "self",
            is_disabled?: false,
            is_primary_member?: true,
            dob: employee_dob
          )
        end
        let(:employee_enrollment) do
          BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: employee_member_id,
            product_price: primary_price 
          )
        end
		    let(:employee_age) { 27 }

        let(:spouse_member_id) { "some_spouse_id" }
        let(:spouse_dob) { Date.new(1995, 9, 27) }
        let(:spouse) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: spouse_member_id,
            relationship: "spouse",
            is_disabled?: false,
            dob: spouse_dob,
            is_primary_member?: false
          )
        end
        let(:spouse_age) { 22 }
        let(:spouse_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: spouse_member_id,
            product_price: dependent_price
          )
        end

				let(:child_member_id) { "some_child1_member_id" }
				let(:child_dob) { Date.new(2015, 1, 1) }
				let(:child) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: child_member_id,
						relationship: "child",
						is_disabled?: false,
						dob: child_dob,
            is_primary_member?: false
					)
				end
        let(:child_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child_member_id,
            product_price: dependent_price
          )
        end
        let(:child_age) { 3 }

        let(:coverage_start_date) { Date.new(2018, 1, 1) }
        let(:rate_schedule_date) { Date.new(2018, 1, 1) }

        let(:family_group_enrollment) do
          BenefitSponsors::Enrollments::GroupEnrollment.new(
            member_enrollments: [employee_enrollment, spouse_enrollment, child_enrollment],
            rate_schedule_date: rate_schedule_date,
            coverage_start_on: coverage_start_date,
            previous_product: nil,
            product: product,
            rating_area: rating_area,
            product_cost_total: family_price
          )
        end

        let(:rating_area) { "DC01" }

        let(:family_roster_entry) do
          ::BenefitSponsors::Members::MemberGroup.new(
            [employee, spouse, child],
            group_enrollment: family_group_enrollment
          )
        end

        let(:family_price) { 320.00 }
        let(:primary_price) { 106.68 }
        let(:dependent_price) { 106.66 }

        let(:total_contribution) { 189.18 }

        let(:employee_contribution_level) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::ContributionLevel,
            contribution_unit_id: "employee_cu_id",
            contribution_factor: 0.50
          )
        end

        let(:spouse_contribution_level) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::ContributionLevel,
            contribution_unit_id: "spouse_cu_id",
            contribution_factor: 0.25
          )
        end

        let(:dependent_contribution_level) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::ContributionLevel,
            contribution_unit_id: "dependent_cu_id",
            contribution_factor: 0.00
          )
        end

        let(:sponsor_contribution) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::ReferenceProductFixedPercentSponsorContribution,
            contribution_levels: [employee_contribution_level, spouse_contribution_level, dependent_contribution_level],
            reference_product: reference_product,
            sic_code: sic_code,
            id: "some cacheable id"
          )
        end
        
        let(:reference_product) { double(id: "reference product id") }

        before(:each) do
					allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
					allow(contribution_model).to receive(:map_relationship_for).with("child", child_age, false).and_return("dependent")
          allow(employee_contribution_unit).to receive(:match?).with({"employee"=>1}).and_return(true)
          allow(employee_contribution_unit).to receive(:match?).with({"spouse"=>1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"dependent"=>1}).and_return(false)
          allow(spouse_contribution_unit).to receive(:match?).with({"employee"=>1}).and_return(false)
          allow(spouse_contribution_unit).to receive(:match?).with({"spouse"=>1}).and_return(true)
          allow(spouse_contribution_unit).to receive(:match?).with({"dependent"=>1}).and_return(false)
          allow(dependent_contribution_unit).to receive(:match?).with({"employee"=>1}).and_return(false)
          allow(dependent_contribution_unit).to receive(:match?).with({"spouse"=>1}).and_return(false)
          allow(dependent_contribution_unit).to receive(:match?).with({"dependent"=>1}).and_return(true)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(reference_product, rate_schedule_date, employee_age, rating_area).and_return(250.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(reference_product, rate_schedule_date, spouse_age, rating_area).and_return(300.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(reference_product, rate_schedule_date, child_age, rating_area).and_return(300.00)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_group_size_factor).with(reference_product, group_size).and_return(1.0)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_sic_code_factor).with(reference_product, sic_code).and_return(1.1)
        end

        it "calculates the total contribution" do
          calculation_result = contribution_calculator.calculate_contribution_for(
            contribution_model,
            family_roster_entry,
            sponsor_contribution
          )
          expect(calculation_result.group_enrollment.sponsor_contribution_total).to eq(total_contribution)
        end

        it "calculates the member contributions" do
          calculation_result = contribution_calculator.calculate_contribution_for(
            contribution_model,
            family_roster_entry,
            sponsor_contribution
          )
          member_total = calculation_result.group_enrollment.member_enrollments.inject(BigDecimal.new("0.00")) do |acc, m_en|
            BigDecimal.new((acc + m_en.sponsor_contribution).to_s).round(2)
          end
          expect(member_total).to eq(total_contribution)
        end
      end
    end
  end
end
