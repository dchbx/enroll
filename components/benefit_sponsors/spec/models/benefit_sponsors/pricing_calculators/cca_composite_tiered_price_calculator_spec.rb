require "rails_helper"

module BenefitSponsors
  RSpec.describe PricingCalculators::CcaCompositeTieredPriceCalculator do
    let(:price_calculator) do
      ::BenefitSponsors::PricingCalculators::CcaCompositeTieredPriceCalculator.new
    end

    let(:pricing_model) do
      instance_double(
        ::BenefitMarkets::PricingModels::PricingModel,
        :pricing_units => pricing_units
      )
    end

    let(:group_size) { 3 }
    let(:participation_percent) { 50 }
    let(:sic_code) { "a sic code" }
    let(:product) { double }

    let(:benefit_roster) do
      benefit_roster_entries
    end

    describe "given:
    - a tiered pricing model
    - with an 'employee_only' group
    - with an 'employee_and_spouse' group
    - with an 'employee_and_dependents' group
    - with a 'family' group" do

      let(:pricing_units) do
        [
          employee_only_pricing_unit,
          employee_and_spouse_pricing_unit,
          employee_and_dependents_pricing_unit,
          family_pricing_unit
        ]
      end

      let(:employee_only_pricing_unit) do
        instance_double(
          ::BenefitMarkets::PricingModels::TieredPricingUnit,
          name: "employee_only",
          id: "employee_only_pu_id"
        )
      end

      let(:employee_and_spouse_pricing_unit) do
        instance_double(
          ::BenefitMarkets::PricingModels::TieredPricingUnit,
          name: "employee_and_spouse",
          id: "employee_and_spouse_pu_id"
        )
      end

      let(:employee_and_dependents_pricing_unit) do
        instance_double(
          ::BenefitMarkets::PricingModels::TieredPricingUnit,
          name: "employee_and_dependents",
          id: "employee_and_dependents_pu_id"
        )
      end

      let(:family_pricing_unit) do
        instance_double(
          ::BenefitMarkets::PricingModels::TieredPricingUnit,
          name: "family",
          id: "family_pu_id"
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
            member_id: employee_member_id
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
            member_id: spouse_member_id
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
            member_id: child_member_id
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
            rating_area: "MA1"
          )
        end

        let(:family_roster_entry) do
          ::BenefitSponsors::Members::MemberGroup.new(
            [employee, spouse, child],
            group_enrollment: family_group_enrollment
          )
        end

        let(:family_price) { 320.00 }

        let(:family_pricing_determination_tier) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::PricingDeterminationTier,
            pricing_unit_id: "family_pu_id",
            price: family_price
          )
        end

        let(:pricing_determination) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::PricingDetermination,
            pricing_determination_tiers: [family_pricing_determination_tier]
          )
        end

        let(:sponsored_benefit) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::SponsoredBenefit,
            latest_pricing_determination: pricing_determination
          )
        end

        let(:sponsor_contribution) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::SponsorContribution,
            sponsored_benefit: sponsored_benefit
          )
        end

        before(:each) do
					allow(pricing_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(pricing_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
					allow(pricing_model).to receive(:map_relationship_for).with("child", child_age, false).and_return("dependent")
          allow(employee_only_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(employee_and_spouse_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(employee_and_dependents_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(family_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(true)
        end

        it "calculates the total price" do
          calculation_result = price_calculator.calculate_price_for(
            pricing_model,
            family_roster_entry,
            sponsor_contribution
          )
          expect(calculation_result.group_enrollment.product_cost_total).to eq(family_price)
        end

        it "calculates the member_prices" do
          calculation_result = price_calculator.calculate_price_for(
            pricing_model,
            family_roster_entry,
            sponsor_contribution
          )
          member_total = calculation_result.group_enrollment.member_enrollments.inject(BigDecimal.new("0.00")) do |acc, m_en|
            BigDecimal.new((acc + m_en.product_price).to_s).round(2)
          end
          expect(member_total).to eq(family_price)
        end
      end
    end
  end
end
