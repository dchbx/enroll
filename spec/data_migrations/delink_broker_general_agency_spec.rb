require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delink_broker_general_agency")

describe DelinkBrokerGeneralAgency, dbclean: :around_each do
  let(:given_task_name) { "delink_broker_general_agency" }
  subject { DelinkBrokerGeneralAgency.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "delink general and broker agency" do
    let(:address) { Address.new(kind: 'primary', address_1: '106 Autumn Hill Way', address_2: '', address_3: '', city: 'Gaithersburg', county: nil, state: 'MD', location_state_code: nil, zip: '20877', country_name: '', full_text: nil) }
    let(:phone) { Phone.new(kind: 'work', country_code: '', area_code: '301', number: '9227984', extension: '', primary: nil, full_phone_number: '3019227984') }
    let(:office_location) { OfficeLocation.new(is_primary: true, address: address, phone: phone) }
    let!(:organization){  Organization.new(:legal_name => "Alvin Frager", :fein => "521698168", :dba => "Alvin Frager Insurance", office_locations: [office_location]) }
    let!(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile, :organization => organization) }
    let!(:general_agency_profile) { FactoryBot.create(:general_agency_profile, :organization => organization) }

    it "should delink general and broker agency" do
      expect(broker_agency_profile.fein).to eq general_agency_profile.fein
      subject.migrate
      expect(BrokerAgencyProfile.all.count).to eq 1
      expect(GeneralAgencyProfile.all.count).to eq 1
      bap = BrokerAgencyProfile.first
      gap = GeneralAgencyProfile.first
      expect(bap.fein).not_to eq gap.fein
      expect(gap.organization.office_locations.first.address.address_1).to eq("1101 Wootton Parkway Suite 820")
      expect(gap.organization.office_locations.first.address.city).to eq("Rockville")
      expect(gap.organization.office_locations.first.address.state).to eq("MD")
      expect(gap.organization.office_locations.first.address.zip).to eq("20852")
    end
  end
end
