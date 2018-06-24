require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delink_broker_agency")

describe DelinkBrokerAgency do

  let(:given_task_name) { "delink_broker_agency" }
  subject { DelinkBrokerAgency.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  let!(:broker_role) { FactoryGirl.create(:broker_role, aasm_state: "active") }
  let!(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, aasm_state: "is_approved", primary_broker_role: broker_role)}
  let!(:person) { FactoryGirl.create(:person)}
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }

  before :each do
    allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
    person.primary_family.broker_agency_accounts.create(broker_agency_profile: broker_agency_profile, writing_agent_id: broker_role.id, start_on: TimeKeeper.date_of_record)
    person.primary_family.save!
  end

  it "should have a broker agency" do
    expect(person.primary_family.current_broker_agency).not_to be_nil
  end

  it "should delink broker agency" do
    subject.migrate
    person.primary_family.reload
    expect(person.primary_family.current_broker_agency).to be_nil
  end
end
