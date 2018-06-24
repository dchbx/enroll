require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "invoke_hub_response")

describe InvokeHubResponse, dbclean: :after_each do

  let(:given_task_name) { "invoke_hub_response" }
  subject { InvokeHubResponse.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "invoke hub response", dbclean: :after_each do

    let!(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:invalid_person) {FactoryGirl.create(:person) }

    before do
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
    end

    it "should invoke hub response succesfully " do
      subject.migrate
      person.consumer_role.reload
      expect(person.consumer_role.aasm_state).not_to eq "unverified"
    end

  end

  describe "should not invoke hub response", dbclean: :after_each do

    let!(:invalid_person) {FactoryGirl.create(:person) }

    before do
      $stdout = StringIO.new
      allow(ENV).to receive(:[]).with('hbx_id').and_return invalid_person.hbx_id
    end

    after(:all) do
      $stdout = STDOUT
    end

    it "should not invoke hub with invalid person" do
      subject.migrate
      expect($stdout.string).to match("Consumer role not found with hbx id #{invalid_person.hbx_id}")
    end

  end
end
