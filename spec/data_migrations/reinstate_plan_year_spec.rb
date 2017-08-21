require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "reinstate_plan_year")

describe ReinstatePlanYear, dbclean: :after_each do

  let(:given_task_name) { "reinstate_plan_year" }
  subject { ReinstatePlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "reinstate_plan_year", dbclean: :after_each do

    let!(:plan_year)         { FactoryGirl.build(:plan_year, aasm_state:'terminated') }
    let!(:employer_profile)  { FactoryGirl.build(:employer_profile,plan_years:[plan_year]) }
    let!(:organization)  { FactoryGirl.create(:organization,employer_profile:employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
    end

    it "plan year state should be active" do
      expect(plan_year.aasm_state).to eq 'terminated'
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq 'active'
    end

    it "should not reinstate plan year" do
      plan_year.update_attributes!(aasm_state:'canceled')
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq 'canceled'
    end
  end
end
