# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::SponsorContribution do

  context "Given valid required parameters" do

    let(:contract)      { BenefitSponsors::Validators::SponsoredBenefits::SponsorContributionContract.new }

    let(:contribution_level) do
      {
        display_name: 'Employee Only', order: 1, contribution_unit_id: 'contribution_unit_id',
        is_offered: true, contribution_factor: 0.75, min_contribution_factor: 0.5,
        contribution_cap: 0.75, flat_contribution_amount: 227.07
      }
    end

    let(:required_params) { {contribution_levels: [contribution_level]}}

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new SponsorContribution instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::SponsorContribution
      end
    end
  end
end