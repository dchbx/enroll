# frozen_string_literal: true

require "rails_helper"

module BenefitSponsors
  RSpec.describe PricingCalculators::ShopSimpleListBillPricingCalculator, :dbclean => :after_each do
    let(:employee_dob) { Date.new(1990, 6, 1) }
    let(:employee_member_id) { "some_employee_id" }
    let(:roster_entry) do
      ::BenefitSponsors::Members::MemberGroup.new(
        roster_members,
        group_enrollment: group_enrollment
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

    let(:product) { double(id: "some_product_id", kind: "health") }

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

    let(:pricing_model) do
      instance_double(
        ::BenefitMarkets::PricingModels::PricingModel,
        pricing_calculator: pricing_calculator,
        id: "a pricing model id",
        pricing_units: pricing_units
      )
    end

    let(:spouse_pricing_unit) do
      instance_double(
        ::BenefitMarkets::PricingModels::RelationshipPricingUnit,
        eligible_for_threshold_discount: false,
        name: "spouse"
      )
    end

    let(:sponsor_contribution) do
      instance_double(
        ::BenefitSponsors::SponsoredBenefits::SponsorContribution
      )
    end

    let(:dependent_pricing_unit) do
      instance_double(
        ::BenefitMarkets::PricingModels::RelationshipPricingUnit,
        eligible_for_threshold_discount: false,
        name: "dependent"
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

    describe "given:
    - a sponsor which offers choice rating
    - with 'employee' and 'spouse' and 'dependent' groups" do

      describe "given:
      - an employee
      - a spouse
      - a child (23)
      - a child (20)
      - a child (19)
      - a child (17)
      - a child (5)
      " do
        let(:pricing_units) { [employee_pricing_unit, spouse_pricing_unit, dependent_pricing_unit] }

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

        let(:child1_member_id) { "some_child1_id" }
        let(:child1_dob) { Date.new(1995, 1, 1) }
        let(:child1) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child1_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child1_dob,
            is_primary_member?: false
          )
        end
        let(:child1_age) { 23 }
        let(:child1_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child1_member_id
          )
        end

        let(:child2_member_id) { "some_child2_id" }
        let(:child2_dob) { Date.new(1998, 1, 1) }
        let(:child2) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child2_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child2_dob,
            is_primary_member?: false
          )
        end
        let(:child2_age) { 20 }
        let(:child2_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child2_member_id
          )
        end

        let(:child3_member_id) { "some_child3_id" }
        let(:child3_dob) { Date.new(1999, 1, 1) }
        let(:child3) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child3_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child3_dob,
            is_primary_member?: false
          )
        end
        let(:child3_age) { 19 }
        let(:child3_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child3_member_id
          )
        end

        let(:child4_member_id) { "some_child4_id" }
        let(:child4_dob) { Date.new(2001, 1, 1) }
        let(:child4) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child4_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child4_dob,
            is_primary_member?: false
          )
        end
        let(:child4_age) { 17 }
        let(:child4_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child4_member_id
          )
        end

        let(:child5_member_id) { "some_child5_id" }
        let(:child5_dob) { Date.new(2001, 1, 1) }
        let(:child5) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child5_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child4_dob,
            is_primary_member?: false
          )
        end
        let(:child5_age) { 5 }
        let(:child5_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child5_member_id
          )
        end

        let(:roster_members) { [employee, spouse, child1, child2, child3, child4, child5] }
        let(:member_enrollments) do
          [
          employee_enrollment,
          spouse_member_enrollment,
          child1_enrollment,
          child2_enrollment,
          child3_enrollment,
          child4_enrollment,
          child5_enrollment
          ]
        end

        before(:each) do
          allow(pricing_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
          allow(pricing_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child1_age, false).and_return("dependent")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child2_age, false).and_return("dependent")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child3_age, false).and_return("dependent")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child4_age, false).and_return("dependent")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child5_age, false).and_return("dependent")
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
            child1_age,
            "MA1"
          ).and_return(75.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child2_age,
            "MA1"
          ).and_return(50.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child3_age,
            "MA1"
          ).and_return(30.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child4_age,
            "MA1"
          ).and_return(20.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child5_age,
            "MA1"
          ).and_return(10.00)
        end

        it "calculates the total" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          expect(result_entry.group_enrollment.product_cost_total).to eq(475.00)
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

        it "calculates the correct child1 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child1_member_id }
          expect(member_entry.product_price).to eq(75.00)
        end

        it "calculates the correct child2 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child2_member_id }
          expect(member_entry.product_price).to eq(50.00)
        end

        it "calculates the correct child3 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child3_member_id }
          expect(member_entry.product_price).to eq(30.00)
        end

        it "calculates the correct child4 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child4_member_id }
          expect(member_entry.product_price).to eq(20.00)
        end

        it "calculates the correct child5 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child5_member_id }
          expect(member_entry.product_price).to eq(0.00)
        end
      end

      describe "given:
    - an employee
    - a spouse
    - a child (23)
    - a child (20)
    - a child (19)
    - a child (17)
    - a child (5)
    - a dental product
    " do
        let(:product) { double(id: "some_product_id", kind: "dental") }

        let(:pricing_units) { [employee_pricing_unit, spouse_pricing_unit, dependent_pricing_unit] }

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

        let(:child1_member_id) { "some_child1_id" }
        let(:child1_dob) { Date.new(1995, 1, 1) }
        let(:child1) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child1_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child1_dob,
            is_primary_member?: false
          )
        end
        let(:child1_age) { 23 }
        let(:child1_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child1_member_id
          )
        end

        let(:child2_member_id) { "some_child2_id" }
        let(:child2_dob) { Date.new(1998, 1, 1) }
        let(:child2) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child2_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child2_dob,
            is_primary_member?: false
          )
        end
        let(:child2_age) { 20 }
        let(:child2_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child2_member_id
          )
        end

        let(:child3_member_id) { "some_child3_id" }
        let(:child3_dob) { Date.new(1999, 1, 1) }
        let(:child3) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child3_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child3_dob,
            is_primary_member?: false
          )
        end
        let(:child3_age) { 19 }
        let(:child3_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child3_member_id
          )
        end

        let(:child4_member_id) { "some_child4_id" }
        let(:child4_dob) { Date.new(2001, 1, 1) }
        let(:child4) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child4_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child4_dob,
            is_primary_member?: false
          )
        end
        let(:child4_age) { 17 }
        let(:child4_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child4_member_id
          )
        end

        let(:child5_member_id) { "some_child5_id" }
        let(:child5_dob) { Date.new(2001, 1, 1) }
        let(:child5) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child5_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child4_dob,
            is_primary_member?: false
          )
        end
        let(:child5_age) { 5 }
        let(:child5_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child5_member_id
          )
        end

        let(:roster_members) { [employee, spouse, child1, child2, child3, child4, child5] }
        let(:member_enrollments) do
          [
          employee_enrollment,
          spouse_member_enrollment,
          child1_enrollment,
          child2_enrollment,
          child3_enrollment,
          child4_enrollment,
          child5_enrollment
          ]
        end

        before(:each) do
          allow(pricing_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
          allow(pricing_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child1_age, false).and_return("dependent")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child2_age, false).and_return("dependent")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child3_age, false).and_return("dependent")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child4_age, false).and_return("dependent")
          allow(pricing_model).to receive(:map_relationship_for).with("child", child5_age, false).and_return("dependent")
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
            child1_age,
            "MA1"
          ).and_return(75.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child2_age,
            "MA1"
          ).and_return(50.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child3_age,
            "MA1"
          ).and_return(30.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child4_age,
            "MA1"
          ).and_return(20.00)
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
            product,
            rate_schedule_date,
            child5_age,
            "MA1"
          ).and_return(10.00)
        end

        it "calculates the total" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          expect(result_entry.group_enrollment.product_cost_total).to eq(495.00)
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

        it "calculates the correct child1 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child1_member_id }
          expect(member_entry.product_price).to eq(75.00)
        end

        it "calculates the correct child2 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child2_member_id }
          expect(member_entry.product_price).to eq(50.00)
        end

        it "calculates the correct child3 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child3_member_id }
          expect(member_entry.product_price).to eq(30.00)
        end

        it "calculates the correct child4 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child4_member_id }
          expect(member_entry.product_price).to eq(20.00)
        end

        it "calculates the correct child5 cost" do
          result_entry = pricing_calculator.calculate_price_for(pricing_model, roster_entry, sponsor_contribution)
          member_entry = result_entry.group_enrollment.member_enrollments.detect { |me| me.member_id == child5_member_id }
          expect(member_entry.product_price).to eq(20.00)
        end
      end
    end
  end
end
