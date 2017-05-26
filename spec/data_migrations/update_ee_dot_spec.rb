require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_ee_dot")

describe UpdateEeDot do

  let(:given_task_name) { "update_ee_dot" }
  subject { UpdateEeDot.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating termination date for an Employee" do
    
    let(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("id").and_return(census_employee.id)
      allow(ENV).to receive(:[]).with("employment_terminated_on").and_return(TimeKeeper.date_of_record - 20.days)
    end

    it "should update date of termination" do
      subject.migrate
      census_employee.reload
      expect(census_employee.employment_terminated_on).to eq (TimeKeeper.date_of_record - 20.days)
    end
  end
end
