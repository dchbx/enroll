require 'rails_helper'

RSpec.describe CarrierServiceArea, type: :model, dbclean: :after_each do
  subject { CarrierServiceArea.new }

  it "has a valid factory" do
    expect(build(:carrier_service_area)).to be_valid
  end

  it { is_expected.to validate_presence_of :issuer_hios_id }
  it { is_expected.to validate_presence_of :service_area_id }
  it { is_expected.to validate_presence_of :service_area_name }
  it { is_expected.to validate_presence_of :serves_entire_state }

  context "serves_entire_state is false" do
    subject { build(:carrier_service_area, serves_entire_state: false) }

    it { is_expected.to validate_presence_of :county_name }
    it { is_expected.to validate_presence_of :county_code }
    it { is_expected.to validate_presence_of :state_code }
  end

  describe "class methods" do
    subject { CarrierServiceArea }

    let!(:full_state_service_area) { create(:carrier_service_area, issuer_hios_id: '11111') }
    let!(:matching_service_area) { create(:carrier_service_area, :for_partial_state, service_area_zipcode: '01225') }
    let!(:non_matching_service_area) { create(:carrier_service_area, :for_partial_state, service_area_zipcode: "01001") }

    let(:carrier_profile) { double(:carrier_profile, issuer_hios_ids: ['11111','22222']) }
    let(:invalid_carrier_profile) { double(:carrier_profile, issuer_hios_ids: ['33333']) }
    let(:address) { double(:address, zip: "01225", "state" => Settings.aca.state_abbreviation) }
    let(:office_location) { double(:office_location, address: address) }

    context "scopes" do
      describe "::serving_entire_state" do
        it "returns only the full state service areas" do
          expect(subject.serving_entire_state).to match([full_state_service_area])
        end
      end

      describe "::for_issuer" do
        it "returns only the matching service area" do
          expect(subject.for_issuer(['11111'])).to match([full_state_service_area])
        end
      end
    end


    context "class methods" do
      describe "::areas_valid_for_zip_code" do
        ## Note this requires a previously validated Mass. Zip Code
        it "returns the matching service areas" do
          expect(subject.send(:areas_valid_for_zip_code, zip_code: '01225')).to match_array([full_state_service_area, matching_service_area])
        end
      end

      describe "::valid_for?" do
        it "returns true if matching service areas" do
          expect(subject.valid_for?(office_location: office_location, carrier_profile: carrier_profile)).to be(true)
        end

        it "returns false if no matches" do
          expect(subject.valid_for?(office_location: office_location, carrier_profile: invalid_carrier_profile)).to be(false)
        end
      end

      describe "::service_areas_for" do
        it "returns matching services areas" do
          expect(subject.service_areas_for(office_location: office_location)).to match_array([full_state_service_area, matching_service_area])
        end
      end
    end
  end ## End class method tests
end
