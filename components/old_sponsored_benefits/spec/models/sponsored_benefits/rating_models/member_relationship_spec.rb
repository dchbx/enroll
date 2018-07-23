require 'rails_helper'

module SponsoredBenefits
  RSpec.describe RatingModels::MemberRelationship, type: :model do

    let(:ordinal_position)          { 1 }
    let(:key)                       { :family }
    let(:title)                     { "Family" }
    let(:member_relationship_kinds) { [:employee, :spouse, :child_under_26] }

    let(:params) do
      {
          ordinal_position: ordinal_position,
          key: key,
          title: title,
          member_relationship_kinds: member_relationship_kinds,
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

      context "with no key" do
        subject { described_class.new(params.except(:key)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no member_relationship_kinds" do
        subject { described_class.new(params.except(:member_relationship_kinds)) }

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


  end
end
