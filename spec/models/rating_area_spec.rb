require 'rails_helper'

RSpec.describe RatingArea, type: :model, dbclean: :after_each do
  subject { RatingArea.new }

  it "has a valid factory" do
    expect(create(:rating_area, zip_code: '99999')).to be_valid
  end

  it { is_expected.to validate_presence_of :zip_code }
  it { is_expected.to validate_presence_of :county_name }
  it { is_expected.to validate_presence_of :rating_area }
  it { is_expected.to validate_presence_of :zip_code_in_multiple_counties }

  context "valididate_uniqueness_of each County / Zip pair" do
    before :all do
      create(:rating_area, county_name: "County", zip_code: "10000")
    end

    let(:invalid_reference) { build(:rating_area, county_name: "County", zip_code: "10000") }
    let(:valid_second_reference) { build(:rating_area, county_name: "Second County", zip_code: '10000') }

    it "does not allow a duplicate reference to be created" do
      expect(invalid_reference.valid?).to be_falsey
      expect(invalid_reference.errors.full_messages.first).to match(/Zip code is already taken/)
    end

    it "allows a new reference in a separate county" do
      expect(valid_second_reference.valid?).to be_truthy
    end
  end

  describe "class methods" do
    subject { RatingArea }

    before :all do
      RatingArea.destroy_all
    end

    describe "::rating_area_for" do
      context "with a valid search param" do
        let(:first_address) { build(:address, county: "County One", zip: "10001") }
        let(:second_address) { build(:address, county: "County One", zip: "10002") }
        let!(:first_county_region) { create(:rating_area, county_name: first_address.county, zip_code: first_address.zip, rating_area: "R-MA001") }
        let!(:same_county_second_region) { create(:rating_area, county_name: second_address.county, zip_code: second_address.zip, rating_area: "R-MA002") }

        it "returns the rating area" do
          expect(subject.rating_area_for(first_address)).to eq("R-MA001")
          expect(subject.rating_area_for(second_address)).to eq("R-MA002")
        end
      end

      context "with an invalid search" do
        let(:invalid_address) { build(:address, county: "Baltimore", zip: "21208") }

        it "returns nil" do
          expect(subject.rating_area_for(invalid_address)).to be_nil
        end
      end
    end

    describe "::find_zip_codes_for" do
      context "with a valid county" do
        let!(:first_county_region) { create(:rating_area, county_name: "County", zip_code: "10010") }
        let!(:same_county_second_zip) { create(:rating_area, county_name: "County", zip_code: "10020") }

        it "returns an array of zip codes" do
          expect(subject.find_zip_codes_for(county_name: 'County')).to match_array(%w(10010 10020))
        end

        it "returns an empty array if nothing found" do
          expect(subject.find_zip_codes_for(county_name: "Potato")).to match_array([])
        end
      end
    end

    describe "::counties_for_zip_code" do
      let!(:first_county_region) { create(:rating_area, county_name: "County", zip_code: "10011") }
      let!(:different_county_same_zip) { create(:rating_area, county_name: "County Two", zip_code: "10011") }

      it "returns counties with the same zip" do
        expect(subject.find_counties_for(zip_code: "10011")).to match_array(['County', 'County Two'])
      end
    end
  end
end
