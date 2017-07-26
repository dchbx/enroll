require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_employer_status")


describe UpdateEmployerStatus, dbclean: :after_each do

  let(:given_task_name) { "employer_status_to_enrolled" }
  subject { UpdateEmployerStatus.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating aasm_state of the employer profile to enrolled", dbclean: :after_each do
    let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "application_ineligible") }
    let(:employer_profile){ FactoryGirl.build(:employer_profile, aasm_state:'registered', plan_years: [plan_year]) }
    let(:organization)  {FactoryGirl.create(:organization,employer_profile:employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
    end

    it "should update aasm_state of employer profile" do
      subject.migrate
      employer_profile.reload
      expect(employer_profile.aasm_state).to eq "enrolled"
    end

    it "should update aasm_state of plan year" do
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "enrolled"
    end

    it "should not update aasm_state of employer profile for invalid state" do
      employer_profile.aasm_state='ineligile'
      employer_profile.save
      subject.migrate
      employer_profile.reload
      expect(employer_profile.aasm_state).to eq "ineligile"
    end

    it "should not should update aasm_state of plan year when ENV['plan_year_start_on'] is empty" do
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return('')
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "application_ineligible"
    end
  end
end
