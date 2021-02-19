# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::OfficeLocations::OfficeLocation do

  context "Given valid required parameters" do

    # let(:contract)      { BenefitSponsors::Validators::OfficeLocations::OfficeLocationContract.new }
    let(:phone) do
      {
        kind: "work", area_code: "483", number: "7897489", full_phone_number: "4837897489"
      }
    end

    let(:address) do
      {
        kind: 'primary', address_1: "dc", address_2: "dc", city: "dc", state: "dc", zip: "12345"
      }
    end

    let(:required_params) do
      {
        is_primary: true,  phone: phone, address: address
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        # expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new OfficeLocation instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::OfficeLocations::OfficeLocation
      end
    end
  end
end