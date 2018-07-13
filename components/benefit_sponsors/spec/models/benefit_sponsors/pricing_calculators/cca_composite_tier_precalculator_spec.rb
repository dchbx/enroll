require "rails_helper"

module BenefitSponsors
  RSpec.describe PricingCalculators::CcaCompositeTierPrecalculator do
    let(:tier_precalculator) do
      ::BenefitSponsors::PricingCalculators::CcaCompositeTierPrecalculator.new
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

      describe "with one family that has:
        - an employee
        - a spouse
        - a child
      and another family that has:
        - an employee
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

        let(:employee_and_dependent_group_enrollment) do
          BenefitSponsors::Enrollments::GroupEnrollment.new(
            member_enrollments: [employee_enrollment, child_enrollment],
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

        let(:employee_and_dependent_roster_entry) do
          ::BenefitSponsors::Members::MemberGroup.new(
            [employee, child],
            group_enrollment: employee_and_dependent_group_enrollment
          )
        end

        let(:benefit_roster_entries) do
          [family_roster_entry, employee_and_dependent_roster_entry]
        end

        before(:each) do
					allow(pricing_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(pricing_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
					allow(pricing_model).to receive(:map_relationship_for).with("child", child_age, false).and_return("dependent")
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            employee_age,
            "MA1"
            ).and_return(200.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            spouse_age,
            "MA1"
            ).and_return(100.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child_age,
            "MA1"
            ).and_return(50.00)
          allow(employee_only_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(employee_and_spouse_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(employee_and_dependents_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(family_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(true)
          allow(employee_only_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1}).and_return(false)
          allow(employee_and_spouse_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1}).and_return(false)
          allow(employee_and_dependents_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1}).and_return(true)
          allow(family_pricing_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1}).and_return(false)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_composite_tier_factor).with(product, "employee_only").and_return(1.0)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_composite_tier_factor).with(product, "employee_and_spouse").and_return(1.5)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_composite_tier_factor).with(product, "employee_and_dependents").and_return(2.0)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_composite_tier_factor).with(product, "family").and_return(2.5)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_group_size_factor).with(product, group_size).and_return(1.0)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_sic_code_factor).with(product, sic_code).and_return(1.0)
          allow(::BenefitMarkets::Products::ProductFactorCache).to receive(:lookup_participation_percent_factor).with(product, participation_percent).and_return(1.0)
        end

        it "calculates the pricing tiers" do
          calculation_result = tier_precalculator.calculate_composite_base_rates(
            product,
            pricing_model,
            benefit_roster,
            group_size,
            participation_percent,
            sic_code
          )
          expect(calculation_result["employee_only_pu_id"]).to eq(133.33)
          expect(calculation_result["employee_and_spouse_pu_id"]).to eq(200.00)
          expect(calculation_result["employee_and_dependents_pu_id"]).to eq(266.66)
          expect(calculation_result["family_pu_id"]).to eq(333.33)
        end
      end
    end
  end
end
