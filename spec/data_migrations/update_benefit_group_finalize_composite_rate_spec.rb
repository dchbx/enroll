require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_benefit_group_finalize_composite_rate")


describe UpdateBenefitGroupFinalizeCompositeRate, dbclean: :after_each do

  let(:given_task_name) { "calculate_benefit_group_finalize_composite_rate" }
  subject { UpdateBenefitGroupFinalizeCompositeRate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating aasm_state of the renewing plan year", dbclean: :after_each do
    let(:benefit_group2) { FactoryGirl.build(:benefit_group, plan_option_kind: "sole_source") }
    let(:benefit_group) { FactoryGirl.build(:benefit_group, plan_option_kind: "sole_source") }
    let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active",benefit_groups:[benefit_group]) }
    let(:canceled_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "canceled",benefit_groups:[benefit_group2]) }
    let(:employer_profile){ FactoryGirl.build(:employer_profile, plan_years: [plan_year,canceled_plan_year]) }
    let(:organization)  {FactoryGirl.create(:organization,employer_profile:employer_profile)}
    let!(:composite_tier_contribution) {plan_year.benefit_groups.first.composite_tier_contributions.first}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
    end

    it "should calculate final tier premium amount" do
      expect(composite_tier_contribution.final_tier_premium).to eq nil
      subject.migrate
      composite_tier_contribution.reload
      plan_year.reload
      expect(composite_tier_contribution.final_tier_premium).to eq 0.0
    end

    it "employer with multiple plan year with same py start date,should pick active plan year to calculate final tier premium amount" do
      subject.migrate
      composite_tier_contribution.reload
      plan_year.reload
      expect(composite_tier_contribution.final_tier_premium).to eq 0.0
      expect(composite_tier_contribution.benefit_group.plan_year).to eq plan_year
    end
  end
end
