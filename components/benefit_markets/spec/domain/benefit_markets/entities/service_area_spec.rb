# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitMarkets::Entities::ServiceArea do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitMarkets::Validators::Locations::ServiceAreaContract.new }
    let(:required_params) do
      {
        active_year: 2020, issuer_provided_title: 'Title', issuer_provided_code: 'issuer_provided_code',
        issuer_profile_id: BSON::ObjectId.new, issuer_hios_id: 'issuer_hios_id',
        county_zip_ids: [{}], covered_states: [{}]
      }
    end

    context "with all/required params" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new ServiceArea instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::ServiceArea
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end
  end
end