require 'rails_helper'

module SponsoredBenefits
  RSpec.describe RatingModels::RatingTier, type: :model do

    let(:ordinal_position)                  { 1 }
    let(:key)                               { :family }
    let(:title)                             { "Family" }
    let(:is_offered)                        { :true }
    let(:sponsor_contribution_factor_kind)  { :percentage_of_reference_plan }
    let(:sponsor_contribution_minimum)      { 0.75 }
    let(:sponsor_contribution_maximum)      { 750.0 }
    let(:member_to_tier_maps)               { [ FactoryGirl.build(:sponsored_benefits_rating_models_member_to_tier_map) ] }


    let(:params) do
      {
          ordinal_position: ordinal_position,
          key: key,
          title: title,
          is_offered: is_offered,
          sponsor_contribution_factor_kind: sponsor_contribution_factor_kind,
          sponsor_contribution_minimum: sponsor_contribution_minimum,
          sponsor_contribution_maximum: sponsor_contribution_maximum,
          member_to_tier_maps: member_to_tier_maps,
        }
    end

    context "when initialized" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no ordinal_position" do
        subject { described_class.new(params.except(:ordinal_position)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no is_offered" do
        subject { described_class.new(params.except(:is_offered)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no sponsor_contribution_factor_kind" do
        subject { described_class.new(params.except(:sponsor_contribution_factor_kind)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with an invalid sponsor_contribution_factor_kind" do
        subject { described_class.new(params.except(:sponsor_contribution_factor_kind)) }

        before { subject.sponsor_contribution_factor_kind = :invalid_factor }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no sponsor_contribution_minimum" do
        subject { described_class.new(params.except(:sponsor_contribution_minimum)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no member_to_tier_maps" do
        subject { described_class.new(params.except(:member_to_tier_maps)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end
    end


    context "with congress member categories" do
      let(:employee_only_map)                         { SponsoredBenefits::RatingModels::MemberRelationship.new(ordinal_position: 1, key: :employee_only) }
      let(:employee_plus_one_dependent_map)           { SponsoredBenefits::RatingModels::MemberRelationship.new(ordinal_position: 2, key: :employee_plus_one_dependent) }
      let(:employee_plus_two_or_more_dependents_map)  { SponsoredBenefits::RatingModels::MemberRelationship.new(ordinal_position: 3, key: :employee_plus_two_or_more_dependents, ) }

      let(:sponsor_credit_structure_kind)             { :percent_with_cap }
      let(:contribution_percent_minimum)              {   75 }
      let(:ee_only_contribution_cap_amount)           {  496.71 }
      let(:ee_plus_one_dep_contribution_cap_amount)   { 1063.83 }
      let(:ee_plus_two_dep_contribution_cap_amount)   { 1130.09 }


      it "should correctly build member_relationships"

      it "should correctly build three rating_tiers"

      it "should correctly build build and persist rating model"

    end

    context "with SHOP Market age based categories" do
    end

    context "with SHOP Market sole source categories" do
    end

    context "with Individual Market age based categories" do
    end



  end
end
