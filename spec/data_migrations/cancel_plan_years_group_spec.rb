require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "cancel_plan_years_group")

describe "Importing data", dbclean: :after_each do
    let!(:given_task_name)    {"cancel_plan_years_group"}
    let!(:organization_1)     { FactoryGirl.create(:organization, :fein => 122121789) }
    let!(:organization_2)     { FactoryGirl.create(:organization, :fein => 122144789) }
    let!(:employer_profile_1) { FactoryGirl.create(:employer_profile, organization: organization_1) }
    let!(:employer_profile_2) { FactoryGirl.create(:employer_profile, organization: organization_2) }
    let!(:benefit_group_1)    { FactoryGirl.build(:benefit_group)}
    let!(:benefit_group_2)    { FactoryGirl.build(:benefit_group)}
    let!(:start_on)           { Date.strptime('07/01/2017','%m/%d/%Y').to_date}
    let!(:start_on_1)         { Date.strptime('08/01/2017','%m/%d/%Y').to_date}
    let!(:plan_year1)         { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group_1], aasm_state: "application_ineligible", start_on: start_on, employer_profile: employer_profile_1) }
    let!(:plan_year2)         { FactoryGirl.create(:plan_year, aasm_state: "active", employer_profile: employer_profile_1 )}
    let!(:plan_year3)         { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group_2], aasm_state: "draft", start_on: start_on, employer_profile: employer_profile_2) }
    let!(:plan_year4)         { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group_2], aasm_state: "draft", start_on: start_on_1, employer_profile: employer_profile_2) }
    let!(:plan_year5)         { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group_2], aasm_state: "publish_pending", start_on: start_on, employer_profile: employer_profile_2) }
  	subject { CancelPlanYearsGroup.new(given_task_name, double(:current_scope => nil)) }
    
    before :each do   
      allow(ENV).to receive(:[]).with('file_name').and_return "spec/test_data/cancel_plan_years/CancelPlanYears.csv"
    end

    it "should cancel the plan year for matching the fein start_on and aasm_state" do
      expect(plan_year1.aasm_state).to eq("application_ineligible")
      subject.migrate
      plan_year1.reload
      expect(plan_year1.aasm_state).to eq("canceled")
    end
    it "should not cancel/effect the second plan year of the same employer" do
      expect(plan_year2.aasm_state).to eq("active")
      subject.migrate
      plan_year2.reload
      expect(plan_year2.aasm_state).to eq("active")
    end
    it "should not cancel the plan year for plan year state not matching" do
      expect(plan_year3.aasm_state).to eq("draft")
      subject.migrate
      plan_year3.reload
      expect(plan_year3.aasm_state).to eq("draft")
    end
    it "should not cancel the plan year for start on date not matching" do
      expect(plan_year4.aasm_state).to eq("draft")
      subject.migrate
      plan_year4.reload
      expect(plan_year4.aasm_state).to eq("draft")
    end

    it "should not cancel the plan year for all the valid details" do
      expect(plan_year5.aasm_state).to eq("publish_pending")
      subject.migrate
      plan_year5.reload
      expect(plan_year5.aasm_state).to eq("canceled")
    end
end