require "rails_helper"

describe Importers::ConversionEmployerUpdate, :dbclean => :after_each do

  let(:employer_profile) { FactoryGirl.create(:employer_profile, profile_source: 'conversion') }
  let(:carrier_profile) { FactoryGirl.create(:carrier_profile) }
  let(:broker_agency_profile){ FactoryGirl.create(:broker_agency_profile) }
  let(:broker_role) { FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile.id) }

  let(:record_attrs) {
    {
      action: "Update",
      fein: employer_profile.fein,
      broker_npn: broker_role.npn,
      contact_first_name: "test1",
      contact_last_name: "test2",
      contact_phone: "8987896788",
      primary_location_address_1: "444 new stream dr",
      primary_location_city: "sterling",
      primary_location_state: "dc",
      primary_location_zip: "99999",
      primary_location_county: 'County',
      legal_name: "xyz llc",
      registered_on: TimeKeeper.date_of_record.beginning_of_month
    }
  }

  context ".save" do

    before(:each) do
      DatabaseCleaner.clean
      @organization = employer_profile.organization
    end

    it "should update employer data correctly with no errors" do
      record = ::Importers::ConversionEmployerUpdate.new(record_attrs)
      record.save
      @organization.reload
      expect(@organization.legal_name).to eq record_attrs[:legal_name]
      expect(@organization.employer_profile.broker_agency_accounts.first.broker_agency_profile_id).to eq broker_agency_profile.id
      expect(@organization.employer_profile.broker_agency_accounts.first.writing_agent_id).to eq broker_role.id
    end

    it "should throw error if data was updated before import" do
      employer_profile.entity_kind = "partnership"
      employer_profile.save
      record = ::Importers::ConversionEmployerUpdate.new(record_attrs)
      record.save
      expect(record.errors.messages[:employer_profile]).to be_present
      expect(record.errors.messages[:employer_profile]).to eq ["import cannot be done as employer updated the info on #{employer_profile.updated_at}"]
    end

  end
end
