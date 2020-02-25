# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::ContributionModels::ContributionModelContract do

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

  let(:missing_params) do
    {
      title: title, key: key,
      sponsor_contribution_kind: sponsor_contribution_kind,
      contribution_calculator_kind: contribution_calculator_kind,
      product_multiplicities: product_multiplicities,
      contribution_units: contribution_units
    }
  end

  let(:invalid_params)   { missing_params.merge({many_simultaneous_contribution_units: 'abc'}) }
  let(:error_message1)   { {:many_simultaneous_contribution_units => ["is missing"], :member_relationships => ["is missing"]} }
  let(:error_message2)   { {:many_simultaneous_contribution_units => ["must be boolean"], :member_relationships => ["is missing"]} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message1 }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq error_message2 }
    end
  end

  context "Given valid required parameters" do
    let(:required_params)  { missing_params.merge({ many_simultaneous_contribution_units: true, member_relationships: member_relationships}) }

    context "with a required only" do
      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end