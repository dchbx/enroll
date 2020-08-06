# frozen_string_literal: true

require "rails_helper"

module BenefitMarkets
  module PricingModelsMocks
    class MockPriceCalculator
    end
  end

  RSpec.describe PricingModels::PricingModel do
    describe "given nothing" do
      it "is invalid" do
        expect(subject.valid?).to be_falsey
      end

      it "is missing a name" do
        subject.valid?
        expect(subject.errors.key?(:name)).to be_truthy
      end

      it "is missing pricing units" do
        subject.valid?
        expect(subject.errors.key?(:pricing_units)).to be_truthy
      end

      it "is missing member relationships" do
        subject.valid?
        expect(subject.errors.key?(:member_relationships)).to be_truthy
      end

      it "is missing price calculator kind" do
        subject.valid?
        expect(subject.errors.key?(:price_calculator_kind)).to be_truthy
      end
    end

    describe "given a price calculator kind" do

      subject do
        PricingModels::PricingModel.new({
                                          :price_calculator_kind => "::BenefitMarkets::PricingModelsMocks::MockPriceCalculator"
                                        })
      end

      it "has access to the specified calculator" do
        expect(subject.pricing_calculator.is_a?(::BenefitMarkets::PricingModelsMocks::MockPriceCalculator)).to be_truthy
      end
    end

    describe ".map_relationship_for" do
      let(:pricing_model) { FactoryBot.build :benefit_markets_pricing_models_pricing_model }

      it "should return nil" do
        expect(pricing_model.map_relationship_for("child_over_26", 27, false)).to be_nil
      end

      it "should return matched member relationship" do
        expect(pricing_model.map_relationship_for("child", 16, false)).to eq :dependent
      end

    end




  end
end
