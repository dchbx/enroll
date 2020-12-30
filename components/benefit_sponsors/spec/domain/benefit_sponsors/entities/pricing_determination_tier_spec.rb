# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::PricingDeterminationTier do

  context "Given valid required parameters" do

    let(:contract)      { BenefitSponsors::Validators::SponsoredBenefits::PricingDeterminationTierContract.new }

    let(:required_params) do
      {
        pricing_unit_id: '0192837465', price: 227.0
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new PricingDeterminationTier instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::PricingDeterminationTier
      end
    end
  end
end