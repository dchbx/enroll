require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_renewing_plan_year_aasm_state")


describe ChangeRenewingPlanYearAasmState do

  let(:given_task_name) { "change_renewing_plan_year_aasm_state" }
  subject { ChangeRenewingPlanYearAasmState.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating aasm_state of the renewing plan year", dbclean: :after_each do
    let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_publish_pending") }
    let(:employer_profile){ FactoryGirl.build(:employer_profile, plan_years: [plan_year]) }
    let(:organization)  {FactoryGirl.create(:organization,employer_profile:employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
    end
    
    it "should update aasm_state of plan year" do
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "renewing_enrolling"
    end

    it "should not should update aasm_state of plan year when ENV['plan_year_start_on'] is empty" do
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return('')
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "renewing_publish_pending"
    end

    ["renewing_publish_pending", "renewing_application_ineligible"].each do |plan_year_state|
      it "should update aasm_state of plan year" do
        plan_year.update_attributes(aasm_state: plan_year_state)
        subject.migrate
        plan_year.reload
        expect(plan_year.aasm_state).to eq "renewing_enrolling"
      end
    end
  end
end