require 'rails_helper'

module SponsoredBenefits
  RSpec.describe RatingModels::RatingFactor, type: :model do

    let(:rating_model_key)  { :health_composite_rating_model }
    let(:key)               { :group_participation_ratio }
    let(:value)             { 1.0 }

    let(:params) do
      {
          rating_model_key: rating_model_key,
          key: key,
          value: value,
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

      context "with no rating_model_key" do
        subject { described_class.new(params.except(:rating_model_key)) }

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

      context "with no value" do
        subject { described_class.new(params.except(:value)) }

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
