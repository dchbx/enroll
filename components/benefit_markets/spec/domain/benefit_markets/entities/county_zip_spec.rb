# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Entities::CountyZip do

  context "Given valid required parameters" do

    let(:contract)          { BenefitMarkets::Validators::Locations::CountyZipContract.new }
    let(:required_params)   { {_id: BSON::ObjectId.new, county_name: 'abc county', zip: '22222', state: 'dc'} }

    context "with all/required params" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new CountyZip instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::CountyZip
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end
  end
end