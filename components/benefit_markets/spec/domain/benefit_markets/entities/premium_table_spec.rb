# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Entities::PremiumTable do

  context "Given valid required parameters" do
    let(:contract)            { BenefitMarkets::Validators::Products::PremiumTableContract.new }

    let(:effective_date)      { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:effective_period)    { effective_date.beginning_of_year..effective_date.end_of_year }

    let(:required_params)     { {_id: BSON::ObjectId.new, effective_period: effective_period, rating_area_id: BSON::ObjectId.new, premium_tuples: nil} }

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new PremiumTable instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::PremiumTable
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end

    context "with all params" do
      let(:all_params) { required_params.merge({premium_tuples: [{_id: BSON::ObjectId.new, age: 12, cost: 227.07}]}) }

      it "contract validation should pass" do
        expect(contract.call(all_params).to_h).to eq all_params
      end

      it "should create new PremiumTable instance" do
        expect(described_class.new(all_params)).to be_a BenefitMarkets::Entities::PremiumTable
        expect(described_class.new(all_params).to_h).to eq all_params
      end
    end
  end
end