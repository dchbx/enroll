# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::Profiles::AcaShopDcEmployerProfile do

  context "Given valid required parameters" do

    let(:contract)      { BenefitSponsors::Validators::Profiles::AcaShopDcEmployerProfileContract.new }

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

    let(:office_location) do
      {
        is_primary: true, address: address, phone: phone
      }
    end


    let(:params) do
      {
        is_benefit_sponsorship_eligible: false,
        contact_method: :electronic_only, office_locations: [office_location],
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(params).to_h).to eq params
      end

      it "should create new Organization instance" do
        expect(described_class.new(params)).to be_a BenefitSponsors::Entities::Profiles::AcaShopDcEmployerProfile
      end
    end
  end
end