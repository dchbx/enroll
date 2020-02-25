# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Entities::PricingModel do

  context "Given valid required parameters" do

    let(:contract)           { BenefitMarkets::Validators::PricingModels::PricingModelContract.new }
    let(:pricing_units)            { [{name: 'name', display_name: 'Employee Only', order: 1}] }
    let(:member_relationships)     { [{relationship_name: :employee, relationship_kinds: [{}], age_threshold: 18, age_comparison: :==, disability_qualifier: true  }] }

    let(:required_params)  do
      {
        price_calculator_kind: 'price_calculator_kind', name: 'Composite Price Model', pricing_units: pricing_units,
        member_relationships: member_relationships, product_multiplicities: [:product_multiplicities1, :product_multiplicities2]
      }
    end

    context "with all/required params" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new PricingModel instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::PricingModel
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end
  end
end