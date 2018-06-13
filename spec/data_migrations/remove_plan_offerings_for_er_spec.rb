require 'rails_helper'
require File.join(Rails.root, "app", "data_migrations", "remove_plan_offerings_for_er")

describe RemovePlanOfferings, dbclean: :after_each do
  let(:given_task_name) { "remove_plan_offerings" }
  subject { RemovePlanOfferings.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "remove the plans of specific carrier for an er " do
    let(:organization){ FactoryGirl.create(:organization) }
    let(:active_benefit_group_ref_plan) {FactoryGirl.create(:plan, active_year:TimeKeeper.date_of_record.year - 1)}
    let(:active_benefit_group_ref_plan2) {FactoryGirl.create(:plan, active_year:TimeKeeper.date_of_record.year - 1)}
    let(:benefit_group) { FactoryGirl.build(:benefit_group, reference_plan_id:active_benefit_group_ref_plan.id, elected_plan_ids:[active_benefit_group_ref_plan.id, active_benefit_group_ref_plan2.id]) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
    let(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, benefit_groups:[benefit_group])}
    before(:each) do
      ENV['fein'] = employer_profile.fein
      ENV['aasm_state'] = plan_year.aasm_state
      ENV['carrier_profile_id'] = benefit_group.elected_plans.last.carrier_profile_id
    end
    it "should remove plan from er" do
      allow(EmployerProfile).to receive(:find).and_return(employer_profile)
      allow(employer_profile).to receive(:find_plan_year).and_return(plan_year)
      expect(organization.employer_profile.plan_years.first.benefit_groups.first.elected_plans.count).to eq 2
      subject.migrate
      organization.reload
      expect(organization.employer_profile.plan_years.first.benefit_groups.first.elected_plans.count).to eq 1
    end
  end
end


