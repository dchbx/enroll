# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::ContributionLevel do

  context "Given valid required parameters" do

    let(:contract)                { BenefitSponsors::Validators::SponsoredBenefits::ContributionLevelContract.new }

    let(:display_name)             { 'Employee Only' }
    let(:contribution_unit_id)     { 'contribution_unit_id' }
    let(:is_offered)               { true }
    let(:contribution_factor)      { 0.75 }
    let(:min_contribution_factor)  { 0.5 }
    let(:contribution_cap)         { 0.75 }
    let(:flat_contribution_amount) { 227.07 }

    let(:required_params) do
      {
        display_name: display_name, contribution_unit_id: contribution_unit_id, is_offered: is_offered,
        contribution_factor: contribution_factor, contribution_cap: contribution_cap, order: 1,
        min_contribution_factor: min_contribution_factor, flat_contribution_amount: flat_contribution_amount
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new ContributionLevel instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::ContributionLevel
      end
    end
  end
end