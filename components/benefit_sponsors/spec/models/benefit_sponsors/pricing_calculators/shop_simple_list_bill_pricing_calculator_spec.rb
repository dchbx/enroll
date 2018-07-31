require "rails_helper"

module BenefitSponsors
  RSpec.describe PricingCalculators::ShopSimpleListBillPricingCalculator do
    let(:employee_dob) { Date.new(1990, 6, 1) }
    let(:employee_member_id) { "some_employee_id" }
    let(:roster_entry) do
      ::BenefitSponsors::Members::MemberGroup.new(
        roster_members,
        group_enrollment: group_enrollment,
      )
    end

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

    let(:group_enrollment) do
      BenefitSponsors::Enrollments::GroupEnrollment.new(
        member_enrollments: member_enrollments,
        rate_schedule_date: rate_schedule_date,
        coverage_start_on: coverage_start_date,
        previous_product: nil,
        product: product,
        rating_area: "MA1"
      )
    end

    let(:employee_enrollment) do
      BenefitSponsors::Enrollments::MemberEnrollment.new(
        member_id: employee_member_id
      )
    end

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

    let(:employee_age) { 27 }

    let(:product) { double(id: "some_product_id") }

    let(:coverage_start_date) { Date.new(2018, 1, 1) }
    let(:rate_schedule_date) { Date.new(2018, 1, 1) }

    let(:employee_pricing_unit) do
      instance_double(
        ::BenefitMarkets::PricingModels::RelationshipPricingUnit,
        eligible_for_threshold_discount: false,
        name: "employee"
      )
    end

    let(:pricing_calculator) do
      ::BenefitSponsors::PricingCalculators::ShopSimpleListBillPricingCalculator.new
    end

    let(:pricing_model) { 
      instance_double(
        ::BenefitMarkets::PricingModels::PricingModel,
        pricing_calculator: pricing_calculator,
        id: "a pricing model id",
        pricing_units: pricing_units
      )
    }

    let(:spouse_pricing_unit) do
      instance_double(
        ::BenefitMarkets::PricingModels::RelationshipPricingUnit,
        eligible_for_threshold_discount: false,
        name: "spouse"
      )
    end

    let(:sponsor_contribution) do
      instance_double(
        ::BenefitSponsors::SponsoredBenefits::SponsorContribution,
      )
    end

    describe "given:
      - a sponsor which offers choice rating 
      - with 'employee' and 'spouse' groups" do

      describe "given:
        - an employee
        - a spouse" do
        let(:pricing_units) { [employee_pricing_unit, spouse_pricing_unit] }

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
        let(:spouse_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: spouse_member_id
          )
        end

        let(:roster_members) { [employee, spouse] }
        let(:member_enrollments) { [employee_enrollment, spouse_member_enrollment] }

        before(:each) do
          allow(pricing_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
          allow(pricing_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
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
        end

        it "calculates the total" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          expect(result_entry.group_enrollment.product_cost_total).to eq(300.00)
        end

        it "calculates the correct employee cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == employee_member_id }
          expect(member_entry.product_price).to eq(200.00)
        end

        it "calculates the correct spouse cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == spouse_member_id }
          expect(member_entry.product_price).to eq(100.00)
        end
      end
    end
  end
end
