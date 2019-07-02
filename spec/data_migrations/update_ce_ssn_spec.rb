require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_ce_ssn")
describe ChangeFein do
  let(:given_task_name) { "update_ce_ssn" }
  subject { UpdateCeSsn.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change ce ssn" do
    let(:employer_profile)     { FactoryGirl.create(:employer_profile) }
    let(:ce)     { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id) }
    let(:person){FactoryGirl.create(:person,ssn: "123123123")}

    before(:each) do
      allow(ENV).to receive(:[]).with("ce_id").and_return(ce.id)
      allow(ENV).to receive(:[]).with("encrypted_ssn").and_return(person.encrypted_ssn)
    end
    after(:each) do
      DatabaseCleaner.clean
    end
    it "should change ce ssn" do
      ssn = person.ssn
      expect(ce.ssn).not_to eq ssn
      subject.migrate
      ce.reload
      expect(ce.ssn).to eq ssn
    end
  end
end