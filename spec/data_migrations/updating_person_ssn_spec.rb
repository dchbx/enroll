require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "updating_person_ssn")
describe ChangeFein do
  let(:given_task_name) { "updating_person_ssn" }
  subject { UpdatingPersonSsn.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change person ssn" do
    let(:person1){ FactoryGirl.create(:person,ssn:"787878787")}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id_1").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("person_ssn").and_return(person1.ssn)
    end
    after(:each) do
      DatabaseCleaner.clean
    end

    it "should change person ssn" do
      ssn=person1.ssn
      subject.migrate
      person1.reload
      expect(person1.ssn).to eq ssn
    end
  end
end