# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Entities::ContributionModel do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitMarkets::Validators::ContributionModels::ContributionModelContract.new }
    let(:member_relationship_map)   { {_id: BSON::ObjectId.new, relationship_name: :employee, operator: :==, count: 1} }
    let(:contribution_unit) do
      {
        _id: BSON::ObjectId.new,
        name: "Employee",
        display_name: "Employee Only",
        order: 1,
        member_relationship_maps: [member_relationship_map]
      }
    end

    let(:contribution_units)         { [contribution_unit] }
    let(:member_relationships)       { [{_id: BSON::ObjectId.new, relationship_name: :employee, relationship_kinds: [{}], age_threshold: nil, age_comparison: nil, disability_qualifier: nil}] }

    let(:required_params) do
      {
        _id: BSON::ObjectId.new,
        title: 'title', sponsor_contribution_kind: 'sponsor_contribution_kind',
        contribution_calculator_kind: 'contribution_calculator_kind',
        product_multiplicities: [:product_multiplicities1, :product_multiplicities2],
        contribution_units: contribution_units,
        many_simultaneous_contribution_units: true,
        member_relationships: member_relationships,
        key: nil
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new ContributionModel instance" do
        expect(described_class.new(required_params)).to be_a BenefitMarkets::Entities::ContributionModel
        expect(described_class.new(required_params).to_h).to eq required_params
      end
    end

    context "with all params" do
      let(:all_params) { required_params.merge({key: :key}) }

      it "contract validation should pass" do
        expect(contract.call(all_params).to_h).to eq all_params
      end

      it "should create new ContributionModel instance" do
        expect(described_class.new(all_params)).to be_a BenefitMarkets::Entities::ContributionModel
        expect(described_class.new(all_params).to_h).to eq all_params
      end
    end
  end
end