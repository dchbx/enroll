require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "build_individual_market_transition")

describe BuildIndividualMarketTransition do

  let(:given_task_name) { "build_individual_market_transition" }
  subject { BuildIndividualMarketTransition.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "build consumer individual market transitions with role_type consumer" do

    let!(:person1) {FactoryGirl.create(:person, :with_consumer_role)}
    let!(:person2) {FactoryGirl.create(:person, :with_consumer_role, :with_resident_role)}

    before(:each) do
      allow(ENV).to receive(:[]).with("action").and_return "consumer_role_people"
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    it "should build individual market transitions for only people with consumer role" do
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.individual_market_transitions.present?). to eq true
      expect(person2.individual_market_transitions.present?). to eq false
      expect(person1.individual_market_transitions.first.role_type). to eq "consumer"
    end
  end


  describe "build individual market transitions for resident role people with role_type resident" do

    let!(:person1) {FactoryGirl.create(:person, :with_resident_role)}
    let!(:person2) {FactoryGirl.create(:person, :with_consumer_role, :with_employee_role)}
    let!(:person3) {FactoryGirl.create(:person, :with_consumer_role, :with_resident_role)}

    before(:each) do
      allow(ENV).to receive(:[]).with("action").and_return "resident_role_people"
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    it "should build individual market transitions for resident role people" do
      subject.migrate
      person1.reload
      person2.reload
      person3.reload
      expect(person1.individual_market_transitions.present?). to eq true
      expect(person2.individual_market_transitions.present?). to eq false
      expect(person3.individual_market_transitions.present?). to eq false
      expect(person1.individual_market_transitions.first.role_type). to eq "resident"
    end
  end
end
