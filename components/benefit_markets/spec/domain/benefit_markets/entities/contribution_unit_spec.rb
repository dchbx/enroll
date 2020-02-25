# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Entities::ContributionUnit do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitMarkets::Validators::ContributionModels::ContributionUnitContract.new }
    let(:member_relationship_map)    { {relationship_name: :employee, operator: :==, count: 1} }
    let(:required_params)            { {name: 'name1', display_name: 'display_name', order: 1, member_relationship_maps: [member_relationship_map]} }

    context "with all/required params" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new ContributionUnit instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::ContributionUnit
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end
  end
end