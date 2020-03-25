require 'rails_helper'

module BenefitMarkets
  RSpec.describe PricingModels::RelationshipPricingUnit do
    describe "given:
- a name
- an operator
- a count
- a parent pricing_unit
- a parent pricing_model, with member_relationships
- a name that isn't present in the member_relationships
" do
      let(:pricing_unit) do
        PricingModels::RelationshipPricingUnit.new(
          name: "spouse",
          display_name: "spouse",
          order: 0
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

      subject { pricing_model; pricing_unit }

      before do
        allow(subject).to receive(:pricing_model).and_return(pricing_model)
      end

      it "is invalid" do
        expect(subject.valid?).to be_falsey
      end
    end
  end
end
