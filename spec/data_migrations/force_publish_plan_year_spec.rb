require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "force_publish_plan_year")

describe ForcePublishPlanYear do
  let(:given_task_name) { "force_publish_plan_year" }
  subject { ForcePublishPlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "force publishing the plan year", dbclean: :after_each do

  let!(:employer_profile)  { FactoryGirl.create(:employer_profile, organization: organization, plan_years: [plan_year]) }
  let(:plan_year) { FactoryGirl.create(:plan_year, aasm_state: "draft") }
  let(:organization) { FactoryGirl.create(:organization, :with_active_and_renewal_plan_years)}
  let(:start_on) { "07012017" }
    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return organization.employer_profile.parent.fein
      allow(ENV).to receive(:[]).with("py_new_start_on").and_return(plan_year.start_on)
    end

    it "should force publish the plan year" do
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "enrolling"
    end
  end
end