# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::OfficeLocations::Phone do

  context "Given valid required parameters" do

    let(:contract)      { BenefitSponsors::Validators::OfficeLocations::PhoneContract.new }
    let(:required_params) do
      {
        kind: 'primary',  area_code: '123', number: "2489333",
        full_phone_number: '1232489333'
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new Phone instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::OfficeLocations::Phone
      end
    end
  end
end