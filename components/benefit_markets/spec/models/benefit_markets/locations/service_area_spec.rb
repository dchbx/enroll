require 'rails_helper'

module BenefitMarkets
  RSpec.describe Locations::ServiceArea do
    describe "given nothing" do
      before :each do
        subject.valid?
      end

      it "requires an active year" do
        expect(subject.errors.has_key?(:active_year)).to be_truthy
      end

      it "requires an issuer provided code" do
        expect(subject.errors.has_key?(:issuer_provided_code)).to be_truthy
      end

      it "requires a geographic boundry to be specified" do
        expect(subject.errors[:base]).to include("a location covered by the service area must be specified")
      end
    end

    describe "which covers the entire administrative area" do
      subject { Locations::ServiceArea.new(covered_states: ["MA"]) }

      before :each do
        subject.valid?
      end

      it "is satisfied location has been provided" do
        expect(subject.errors[:base]).not_to include("a location covered by the service area must be specified")
      end
    end

    describe "given a county zip pair" do
      subject { Locations::ServiceArea.new(county_zip_ids: [BSON::ObjectId.new]) }

      before :each do
        subject.valid?
      end

      it "is satisfied location has been provided" do
        expect(subject.errors[:base]).not_to include("a location covered by the service area must be specified")
      end
    end

    describe "created for a given zip code and county in a state", :dbclean => :after_each do
      let(:county_zip) { ::BenefitMarkets::Locations::CountyZip.create!(county_name: "Hampshire", zip: "01001", state: "MA") }
      let(:service_area) { ::BenefitMarkets::Locations::ServiceArea.create!(active_year: TimeKeeper.date_of_record.year, county_zip_ids: [county_zip.id], issuer_provided_code: "Some issuer code", issuer_profile_id: BSON::ObjectId.new) }

      let(:address_outside_county) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Baltimore",
          :state => "MA"
        )
      }
      let(:address_outside_zip) {
        OpenStruct.new(
          :zip => "01555",
          :county => "Hampshire",
          :state => "MA"
        )
      }
      let(:address_outside_state) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Hampshire",
          :state => "MD"
        )
      }
      let(:matching_address) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Hampshire",
          :state => "MA"
        )
      }

      after(:each) do
        county_zip.destroy
        service_area.destroy
      end

      it "will not be found when given an address not in that county" do
        service_area
        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address_outside_county)
        expect(service_areas.to_a).not_to include(service_area)
      end

      it "will not be found when given an address not in that zip code" do
        service_area
        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address_outside_zip)
        expect(service_areas.to_a).not_to include(service_area)
      end

      it "will not be found when given an address not in that state" do
        service_area
        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address_outside_state)
        expect(service_areas.to_a).not_to include(service_area)
      end

      it "is found when a matching address is provided" do
        service_area
        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(matching_address)
        expect(service_areas.to_a).to include(service_area)
      end
    end

    describe "created for a given state", :dbclean => :after_each do
      let(:service_area) { ::BenefitMarkets::Locations::ServiceArea.create!(active_year: TimeKeeper.date_of_record.year, covered_states: ["MA"], issuer_provided_code: "Some issuer code", issuer_profile_id: BSON::ObjectId.new) }

      let(:address_outside_state) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Hampshire",
          :state => "MD"
        )
      }
      let(:matching_address) {
        OpenStruct.new(
          :zip => "01001",
          :county => "Hampshire",
          :state => "MA"
        )
      }

      after(:each) do
        service_area.destroy
      end

      it "will not be found when given an address not in that state" do
        service_area
        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address_outside_state)
        expect(service_areas.to_a).not_to include(service_area)
      end

      it "is found when a matching address is provided" do
        service_area
        service_areas = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(matching_address)
        expect(service_areas.to_a).to include(service_area)
      end
    end
  end
end
