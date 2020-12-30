# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::ContributionModels::Create, dbclean: :after_each do

  let(:title)                                 { 'Title' }
  let(:key)                                   { :key }
  let(:sponsor_contribution_kind)             { 'sponsor_contribution_kind'}
  let(:contribution_calculator_kind)          { 'contribution_calculator_kind' }
  let(:many_simultaneous_contribution_units)  { true }
  let(:product_multiplicities)                { [:product_multiplicities1, :product_multiplicities2] }
  let(:member_relationship_map_params)        { {relationship_name: 'Employee', count: 1} }
  let(:member_relationship_map)               { ::BenefitMarkets::ContributionModels::MemberRelationshipMap.new(member_relationship_map_params).as_json }
  let(:member_relationship_maps)              { [member_relationship_map] }
  let(:contribution_unit) do
    ::BenefitMarkets::ContributionModels::ContributionUnit.new(
      _id: BSON::ObjectId.new,
      name: "Employee",
      display_name: "Employee Only",
      order: 1,
      member_relationship_maps: member_relationship_maps
    )
  end

  let(:member_relationship) do
    ::BenefitMarkets::PricingModels::MemberRelationship.new(
      relationship_name: "Employee",
      relationship_kinds: ['self']
    )
  end

  let(:contribution_units)                    { [contribution_unit.as_json] }
  let(:member_relationships)                  { [member_relationship.as_json] }

  let(:params) do
    {
      _id: BSON::ObjectId.new,
      title: title, key: key,
      sponsor_contribution_kind: sponsor_contribution_kind,
      contribution_calculator_kind: contribution_calculator_kind,
      product_multiplicities: product_multiplicities,
      contribution_units: contribution_units,
      many_simultaneous_contribution_units: true,
      member_relationships: member_relationships
    }
  end

  context 'sending required parameters' do
    it 'should create ContributionModel' do
      expect(subject.call(contribution_params: params).success?).to be_truthy
      expect(subject.call(contribution_params: params).success).to be_a BenefitMarkets::Entities::ContributionModel
    end
  end
end
