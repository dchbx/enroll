require 'rails_helper'

=begin
describe ::Forms::PlanYearForm, "when newly created" do
  let(:plan_year_form) { ::Forms::PlanYearForm.new(PlanYear.new(start_on: TimeKeeper.date_of_record)) }

  before do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(2015, 11, 1))
  end

  after do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context "validation" do
    let(:invalid_plan_year_form) {::Forms::PlanYearForm.new(PlanYear.new())}
    before :each do
      invalid_plan_year_form.valid?
    end

    [:start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on].each do |attr|
      it "should have errors on #{attr}" do
        expect(invalid_plan_year_form).to have_errors_on(attr.to_sym)
      end
    end
  end

  context "plans" do
    let(:carrier_profile) {FactoryGirl.build(:carrier_profile)}
    let(:next_year_plan_year_form) { ::Forms::PlanYearForm.new(PlanYear.new(start_on: TimeKeeper.date_of_record + 1.year)) }

    before :each do
      Plan.delete_all
      Rails.cache.clear
      plan = FactoryGirl.create(:plan, active_year: TimeKeeper.date_of_record.year, market: "shop", coverage_kind: "health", carrier_profile: carrier_profile, metal_level: "silver")
      @plan = ["#{::Organization.valid_carrier_names[plan.carrier_profile_id.to_s]} - #{plan.name}", plan.id]
      excluded_metal_level_plan = FactoryGirl.create(:plan, active_year: TimeKeeper.date_of_record.year, market: "shop", coverage_kind: "health", carrier_profile: carrier_profile, metal_level: "catastrophic")
      @excluded_metal_level_plan = ["#{::Organization.valid_carrier_names[excluded_metal_level_plan.carrier_profile_id.to_s]} - #{excluded_metal_level_plan.name}", excluded_metal_level_plan.id.to_s]
      excluded_market_plan = FactoryGirl.create(:plan, active_year: TimeKeeper.date_of_record.year, market: "individual", coverage_kind: "health", carrier_profile: carrier_profile, metal_level: "silver")
      @excluded_market_plan = ["#{::Organization.valid_carrier_names[:excluded_market_plan]} - #{excluded_market_plan.name}", excluded_market_plan.id.to_s]
      excluded_coverage_kind_plan = FactoryGirl.create(:plan, active_year: TimeKeeper.date_of_record.year, market: "shop", coverage_kind: "dental", carrier_profile: carrier_profile, metal_level: "silver", dental_level: "high")
      @excluded_coverage_kind_plan = ["#{::Organization.valid_carrier_names[:excluded_coverage_kind_plan]} - #{excluded_coverage_kind_plan.name}", excluded_coverage_kind_plan.id.to_s]
      FactoryGirl.create(:plan, active_year: (TimeKeeper.date_of_record.year - 1), carrier_profile: carrier_profile)
      FactoryGirl.create(:plan, market: "individual", carrier_profile: carrier_profile)
      FactoryGirl.create(:plan, coverage_kind: "dental", carrier_profile: carrier_profile, dental_level: "low")
    end

    describe "asked to provide plans for a carrier" do
      it "should include the expected plan" do
        expect(plan_year_form.carrier_plans_for(carrier_profile.id)).to include(@plan)
      end

      it "should not include the expected plan in next year" do
        expect(next_year_plan_year_form.carrier_plans_for(carrier_profile.id)).not_to include(@plan)
      end

      it "should not include dental" do
        expect(plan_year_form.carrier_plans_for(carrier_profile.id)).not_to include(@excluded_coverage_kind_plan)
      end

      it "should not include individual" do
        expect(plan_year_form.carrier_plans_for(carrier_profile.id)).not_to include(@excluded_market_plan)
      end

      it "should not include catastrophic" do
        expect(plan_year_form.carrier_plans_for(carrier_profile.id)).not_to include(@excluded_metal_level_plan)
      end
    end

    describe "asked to provide plans for a metal level" do
      it "should include the expected plan" do
        expect(plan_year_form.metal_level_plans_for("silver")).to include(@plan)
      end

      it "should not include the expected plan in next year" do
        expect(next_year_plan_year_form.metal_level_plans_for("silver")).not_to include(@plan)
      end

      it "should not include dental" do
        expect(plan_year_form.metal_level_plans_for("silver")).not_to include(@excluded_coverage_kind_plan)
      end

      it "should not include individual" do
        expect(plan_year_form.metal_level_plans_for("silver")).not_to include(@excluded_market_plan)
      end

      it "should not include catastrophic" do
        expect(plan_year_form.metal_level_plans_for("silver")).not_to include(@excluded_metal_level_plan)
      end
    end
  end
end

describe ::Forms::PlanYearForm, "when update" do
  let(:plan_year) { FactoryGirl.build(:plan_year) }
  let(:plan_year_atts) {plan_year.attributes}

  it "change plan_year attributes" do
    plan_year_atts[:msp_count] = 8
    py = ::Forms::PlanYearForm.rebuild(plan_year, plan_year_atts)

    expect(py.msp_count).to eq 8
  end
end
=end
