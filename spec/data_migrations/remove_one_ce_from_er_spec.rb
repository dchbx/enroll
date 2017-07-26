require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_one_ce_from_er")

describe RemoveOneCeFromEr, dbclean: :after_each do

  let(:given_task_name) { "remove_one_ce_from_er" }
  subject { RemoveOneCeFromEr.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove one cenesus employee from employer roaster" do
    let(:organization) { FactoryGirl.create(:organization, :with_active_and_renewal_plan_years)}
    let!(:census_employee1) { FactoryGirl.create :census_employee, employer_profile: organization.employer_profile, dob: TimeKeeper.date_of_record - 30.years}
    let!(:census_employee2) { FactoryGirl.create :census_employee, employer_profile: organization.employer_profile, dob: TimeKeeper.date_of_record - 30.years,
     employee_role: employee_role}
    let(:employee_role) {FactoryGirl.create(:employee_role, employer_profile: organization.employer_profile)}
    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("ce_id").and_return(census_employee1.id)
    end

    it "should remove one census_employee_" do
      expect(organization.employer_profile.census_employees.size).to eq 2
      subject.migrate
      organization.reload
      expect(organization.employer_profile.census_employees.size).to eq 1
    end
    it "should remove the correct census_employee_" do
      ce1_id = census_employee1.id
      subject.migrate
      organization.reload
      expect(organization.employer_profile.census_employees.where(id:ce1_id).size).to eq 0
    end
    it "should not remove the irrelevant census_employee_" do
      ce2_id = census_employee2.id
      subject.migrate
      organization.reload
      expect(organization.employer_profile.census_employees.where(id:ce2_id).size).to eq 1
    end
  end
end
