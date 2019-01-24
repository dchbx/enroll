require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_writing_agent_id")

describe UpdateWritingAgentId, dbclean: :after_each do

  let(:given_task_name) { "update_writing_agent_id" }
  subject { UpdateWritingAgentId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating writing agent id of broker agency account" do

    let!(:person) { FactoryGirl.create(:person) }
    let!(:family) {FactoryGirl.create :family, :with_primary_family_member, person: person, broker_agency_accounts: [broker_account]}
    let(:broker_account) { FactoryGirl.create(:broker_agency_account) }

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("valid_writing_agent_id").and_return("5bff645eb19bcd3db9001234")
      subject.migrate
    end

    it "should change the writing agent id" do
      expect(family.reload.broker_agency_accounts.first.writing_agent_id).to eq BSON::ObjectId.from_string("5bff645eb19bcd3db9001234")
    end
  end
end