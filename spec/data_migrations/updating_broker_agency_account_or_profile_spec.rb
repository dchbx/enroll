require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "updating_broker_agency_account_or_profile")

describe UpdatingBrokerAgencyAccountOrProfile, dbclean: :after_each do 
  
  let!(:given_task_name) { "delinking_broker" }
  let!(:person) { FactoryGirl.create(:person,:with_broker_role)}
  let!(:organization1) {FactoryGirl.create(:organization)}
  let!(:organization) {FactoryGirl.create(:organization)}
  let!(:fein){"929129912"}
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization)}
  let!(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization1)}
  let!(:office_locations_contact) {FactoryGirl.build(:phone, kind: "work")}
  let!(:office_locations) {FactoryGirl.build(:address, kind: "branch")}
  let!(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: person.broker_role.id, is_active: true, employer_profile: employer_profile)}
  let!(:new_person) { FactoryGirl.create(:person)}
  let!(:family) {FactoryGirl.create(:family,:with_primary_family_member, person:new_person, broker_agency_accounts:[broker_agency_account])}

  subject { UpdatingBrokerAgencyAccountOrProfile.new(given_task_name, double(:current_scope => nil)) }
  
  context "create_org_and_broker_agency_profile" do 
    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("legal_name").and_return(organization.legal_name)
      allow(ENV).to receive(:[]).with("fein").and_return(fein)
      allow(ENV).to receive(:[]).with("defualt_general_agency_id").and_return(broker_agency_profile.default_general_agency_profile_id)
      allow(ENV).to receive(:[]).with("npn").and_return(person.broker_role.npn)
      allow(ENV).to receive(:[]).with("address_1").and_return(office_locations.address_1)
      allow(ENV).to receive(:[]).with("address_2").and_return(office_locations.address_2)
      allow(ENV).to receive(:[]).with("city").and_return(office_locations.city)
      allow(ENV).to receive(:[]).with("state").and_return(office_locations.state)
      allow(ENV).to receive(:[]).with("zip").and_return(office_locations.zip)
      allow(ENV).to receive(:[]).with("area_code").and_return(office_locations_contact.area_code)
      allow(ENV).to receive(:[]).with("number").and_return(office_locations_contact.number)
      allow(ENV).to receive(:[]).with("market_kind").and_return(broker_agency_profile.market_kind)
      # allow(ENV).to receive(:[]).with("broker_agency_profile_id").and_return(broker_agency_profile.id.to_s)
      allow(ENV).to receive(:[]).with("action").and_return("create_org_and_broker_agency_profile")
      employer_profile.broker_agency_accounts << broker_agency_account
    end

    it "Should update the person broker_role id with with new broker_agency" do
      subject.migrate
      person.reload
      expect(person.broker_role.broker_agency_profile.organization.fein).to eq fein
    end
  end

   context "update_broker_role" do 
    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("legal_name").and_return(organization.legal_name)
      allow(ENV).to receive(:[]).with("fein").and_return(fein)
      allow(ENV).to receive(:[]).with("defualt_general_agency_id").and_return(broker_agency_profile.default_general_agency_profile_id)
      allow(ENV).to receive(:[]).with("npn").and_return(person.broker_role.npn)
      allow(ENV).to receive(:[]).with("address_1").and_return(office_locations.address_1)
      allow(ENV).to receive(:[]).with("address_2").and_return(office_locations.address_2)
      allow(ENV).to receive(:[]).with("city").and_return(office_locations.city)
      allow(ENV).to receive(:[]).with("state").and_return(office_locations.state)
      allow(ENV).to receive(:[]).with("zip").and_return(office_locations.zip)
      allow(ENV).to receive(:[]).with("area_code").and_return(office_locations_contact.area_code)
      allow(ENV).to receive(:[]).with("number").and_return(office_locations_contact.number)
      allow(ENV).to receive(:[]).with("market_kind").and_return('both')
      allow(ENV).to receive(:[]).with("broker_agency_profile_id").and_return(broker_agency_profile.id.to_s)
      allow(ENV).to receive(:[]).with("action").and_return("update_broker_role")
      employer_profile.broker_agency_accounts << broker_agency_account
    end

    it "Should update the person broker_role id with with new broker_agency" do
      subject.migrate
      person.reload
      expect(person.broker_role.market_kind).to eq 'both'
    end
   end

  context "update_family_broker_agency_account_with_writing_agent" do
    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("legal_name").and_return(organization.legal_name)
      allow(ENV).to receive(:[]).with("fein").and_return(fein)
      allow(ENV).to receive(:[]).with("defualt_general_agency_id").and_return(broker_agency_profile.default_general_agency_profile_id)
      allow(ENV).to receive(:[]).with("npn").and_return(person.broker_role.npn)
      allow(ENV).to receive(:[]).with("address_1").and_return(office_locations.address_1)
      allow(ENV).to receive(:[]).with("address_2").and_return(office_locations.address_2)
      allow(ENV).to receive(:[]).with("city").and_return(office_locations.city)
      allow(ENV).to receive(:[]).with("state").and_return(office_locations.state)
      allow(ENV).to receive(:[]).with("zip").and_return(office_locations.zip)
      allow(ENV).to receive(:[]).with("area_code").and_return(office_locations_contact.area_code)
      allow(ENV).to receive(:[]).with("number").and_return(office_locations_contact.number)
      allow(ENV).to receive(:[]).with("market_kind").and_return('both')
      allow(ENV).to receive(:[]).with("broker_agency_profile_id").and_return(broker_agency_profile.id.to_s)
      allow(ENV).to receive(:[]).with("hbx_id").and_return(new_person.hbx_id)
      allow(ENV).to receive(:[]).with("org_fein").and_return(broker_agency_profile.fein)
      allow(ENV).to receive(:[]).with("action").and_return("update_family_broker_agency_account_with_writing_agent")
    end

    it "Should update the writing agent of broker agency account" do
      new_person.primary_family.broker_agency_accounts.first.update_attributes(writing_agent_id: '')
      expect(new_person.primary_family.broker_agency_accounts.first.writing_agent).to eq nil
      subject.migrate
      new_person.primary_family.reload
      expect(new_person.primary_family.broker_agency_accounts.first.writing_agent).to eq broker_agency_profile.primary_broker_role
    end
  end
end
