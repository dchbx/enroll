require 'rails_helper'

module BenefitMarkets
  RSpec.describe ContributionModels::MemberRelationshipMap do
    describe "given:
- a name
- an operator
- a count
- a parent contribution_unit
- a parent contribution_model, with member_relationships
- a relationship_name that isn't present in the member_relationships
" do
      let(:contribution_unit) do
        ContributionModels::ContributionUnit.new(
          name: "employee_only",
          display_name: "Employee Only",
          member_relationship_maps: [member_relationship_map],
          order: 0
        )
      end

      let(:member_relationship_map) do
        ContributionModels::MemberRelationshipMap.new(
          relationship_name: "spouse",
          operator: :==,
          count: 1
        )
      end

      let(:member_relationship) do
        ContributionModels::MemberRelationship.new(
          relationship_name: "employee",
          relationship_kinds: ["self"]
        )
      end
      let(:contribution_units) { [contribution_unit] }
      let(:member_relationships) { [member_relationship] }

      let(:contribution_model) do
        ContributionModels::ContributionModel.new(
          :contribution_units => contribution_units,
          :member_relationships => member_relationships,
          :title => "Federal Heath Benefits"
        )
      end

      subject { contribution_model; member_relationship_map }
      it "is invalid" do
        expect(subject.valid?).to be_falsey
      end
    end
  end
end
