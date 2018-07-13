require 'rails_helper'

module BenefitMarkets
  RSpec.describe ContributionModels::ContributionUnit do
      subject do
        ::BenefitMarkets::ContributionModels::ContributionUnit.new(
          member_relationship_maps: member_relationship_maps
        )
      end

      let(:member_relationship_map_1) { ::BenefitMarkets::ContributionModels::MemberRelationshipMap.new }
      let(:member_relationship_map_2) { ::BenefitMarkets::ContributionModels::MemberRelationshipMap.new }

      let(:member_relationship_maps) { [member_relationship_map_1, member_relationship_map_2] }

      let(:relationship_hash) do
        { :employee => 1, :dependent => 1 }
      end

      describe "given a hash of relationships which matches all of the member relationship maps" do
        before :each do
          allow(member_relationship_map_1).to receive(:match?).with(relationship_hash).and_return(true)
          allow(member_relationship_map_2).to receive(:match?).with(relationship_hash).and_return(true)
        end

        it "matches" do
          expect(subject.match?(relationship_hash)).to be_truthy
        end
      end

      describe "given a hash of relationships which matches but one of the member relationship maps" do
        before :each do
          allow(member_relationship_map_1).to receive(:match?).with(relationship_hash).and_return(true)
          allow(member_relationship_map_2).to receive(:match?).with(relationship_hash).and_return(false)
        end

        it "does not match" do
          expect(subject.match?(relationship_hash)).to be_falsey
        end
      end
  end
end
