# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::OfficeLocations::Address do

  context "Given valid required parameters" do

    let(:contract)      { BenefitSponsors::Validators::OfficeLocations::AddressContract.new }
    let(:required_params) do
      {
        kind: 'home',  address_1: 'test', city: "dc",
        state: "dc", zip: "22031"
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new Address instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::OfficeLocations::Address
      end
    end
  end
end