# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Entities::RatingArea do

  context "Given valid required parameters" do

    let(:contract)          { BenefitMarkets::Validators::Locations::RatingAreaContract.new }
    let(:required_params)   { {active_year: 2020, exchange_provided_code: 'code', county_zip_ids: [{}], covered_states: [{}] } }

    context "with all/required params" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new RatingArea instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::RatingArea
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end
  end
end