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
        expect(subject.errors.has_key?(:name)).to be_truthy
      end

      it "is missing pricing units" do
        subject.valid?
        expect(subject.errors.has_key?(:pricing_units)).to be_truthy
      end

      it "is missing member relationships" do
        subject.valid?
        expect(subject.errors.has_key?(:member_relationships)).to be_truthy
      end

      it "is missing price calculator kind" do
        subject.valid?
        expect(subject.errors.has_key?(:price_calculator_kind)).to be_truthy
      end
    end

    describe "given a price calculator kind" do

      subject do
        PricingModels::PricingModel.new({
          :price_calculator_kind => "::BenefitMarkets::PricingModelsMocks::MockPriceCalculator"
        })
      end

      it "has access to the specified calculator" do
        expect(subject.pricing_calculator.kind_of?(::BenefitMarkets::PricingModelsMocks::MockPriceCalculator)).to be_truthy
      end
    end
  end
end
