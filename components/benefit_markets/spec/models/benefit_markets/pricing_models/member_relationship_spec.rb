require 'rails_helper'

module BenefitMarkets
  RSpec.describe PricingModels::MemberRelationship do
    describe "for a disabled, >= 27 year old child" do
      subject do
        ::BenefitMarkets::PricingModels::MemberRelationship.new(
         relationship_name: "dependent",
         relationship_kinds: ["child"],
         age_threshold: 27,
         age_comparison: :>=,
         disability_qualifier: true
        )
      end

      describe "given a 23 year old spouse" do
        let(:relationship) { "spouse" }
        let(:disability) { false }
        let(:age) { 23 }

        it "does not match" do
          expect(subject.match?(relationship, age, disability)).to be_falsey
        end
      end

      describe "given a non-disabled 29 year old child" do
        let(:relationship) { "child" }
        let(:disability) { false }
        let(:age) { 29 }

        it "does not match" do
          expect(subject.match?(relationship, age, disability)).to be_falsey
        end
      end

      describe "given a disabled 29 year old child" do
        let(:relationship) { "child" }
        let(:disability) { true }
        let(:age) { 29 }

        it "does not match" do
          expect(subject.match?(relationship, age, disability)).to be_truthy
        end
      end
    end

    describe "given no disability qualifier, for a < 26 year old child" do
      subject do
        ::BenefitMarkets::ContributionModels::MemberRelationship.new(
         relationship_name: "dependent",
         relationship_kinds: ["child"],
         age_threshold: 26,
         age_comparison: :<
        )
      end

      describe "given a disabled 25 year old child" do
        let(:relationship) { "child" }
        let(:disability) { true }
        let(:age) { 25 }

        it "matches" do
          expect(subject.match?(relationship, age, disability)).to be_truthy
        end
      end

      describe "given a non-disabled 23 year old child" do
        let(:relationship) { "child" }
        let(:disability) { false }
        let(:age) { 25 }

        it "matches" do
          expect(subject.match?(relationship, age, disability)).to be_truthy
        end
      end
    end
  end
end
