# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::PricingDetermination do

  context "Given valid required parameters" do

    let(:contract)      { BenefitSponsors::Validators::SponsoredBenefits::PricingDeterminationContract.new }

    let(:pricing_determination_tiers) { [{pricing_unit_id: 'pricing_unit_id', price: 227.07}] }
    let(:required_params) do
      {
        group_size: 4, participation_rate: 0.75, pricing_determination_tiers: pricing_determination_tiers
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new PricingDetermination instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::PricingDetermination
      end
    end
  end
end