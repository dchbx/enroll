# frozen_string_literal: true

require 'rails_helper'

module BenefitMarkets
  RSpec.describe PricingModels::MemberRelationshipMap do
    describe "given:
- a name
- an operator
- a count
- a parent pricing_unit
- a parent pricing_model, with member_relationships
- a relationship_name that isn't present in the member_relationships
" do
      let(:pricing_unit) do
        PricingModels::TieredPricingUnit.new(
          name: "employee_only",
          display_name: "Employee Only",
          member_relationship_maps: [member_relationship_map],
          order: 0
        )
      end

      let(:member_relationship_map) do
        PricingModels::MemberRelationshipMap.new(
          relationship_name: "spouse",
          operator: :==,
          count: 1
        )
      end

      let(:member_relationship) do
        PricingModels::MemberRelationship.new(
          relationship_name: "employee",
          relationship_kinds: ["self"]
        )
      end
      let(:pricing_units) { [pricing_unit] }
      let(:member_relationships) { [member_relationship] }

      let(:pricing_model) do
        PricingModels::PricingModel.new(
          :pricing_units => pricing_units,
          :member_relationships => member_relationships,
          :name => "Federal Heath Benefits"
        )
      end

      subject { pricing_model; member_relationship_map }
      it "is invalid" do
        expect(subject.valid?).to be_falsey
      end
    end
  end
end
