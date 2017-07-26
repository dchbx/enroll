require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delink_broker")

describe DelinkBroker do
  
  let(:given_task_name) { "delink_broker" }
  let(:person) { FactoryGirl.create(:person,:with_broker_role)}
  let(:organization1) {FactoryGirl.create(:organization)}
  let(:organization) {FactoryGirl.create(:organization)}
  let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization)}
  let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization1)}
  let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: person.broker_role.id, is_active: true, employer_profile: employer_profile)}
  subject { DelinkBroker.new(given_task_name, double(:current_scope => nil)) }

  before(:each) do
    allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
    allow(ENV).to receive(:[]).with("legal_name").and_return("legal_name")
    allow(ENV).to receive(:[]).with("fein").and_return("fein")
    allow(ENV).to receive(:[]).with("organization_ids_to_move").and_return(employer_profile.organization.id.to_s)
    employer_profile.broker_agency_accounts << broker_agency_account
  end

  it "Should update the person broker_role id with with new broker_agency" do
    old_broker_agency_profile_id=person.broker_role.broker_agency_profile_id.to_s
    subject.migrate
    person.reload
    expect(old_broker_agency_profile_id.to_s).not_to eq(person.broker_role.broker_agency_profile_id.to_s)
  end
end
