require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::PremiumTuple, type: :model do


    let(:age)   { 25 }
    let(:cost)  { 210.32 }

    let(:params) do
      {
        age:  age,
        cost: cost,
      }
    end

    context "A new PremiumTuple instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do
        context "that's missing age" do
          subject { described_class.new(params.except(:age)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:age]).to include("can't be blank")
          end
        end

        context "that's missing cost" do
          subject { described_class.new(params.except(:cost)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:cost]).to include("can't be blank")
          end
        end

      end

      context "with all valid params" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end
    end

    context "Comparing PremiumTuples" do
      let(:base_premium_tuple)      { described_class.new(**params) }

      context "and they are the same" do
        let(:compare_premium_tuple) { described_class.new(**params) }

        it "they should be different instances" do
          expect(base_premium_tuple.id).to_not eq compare_premium_tuple.id
        end

        it "should match" do
          expect(base_premium_tuple <=> compare_premium_tuple).to eq 0
        end
      end

      context "and the attributes are different" do
        let(:compare_premium_tuple) { described_class.new(**params) }

        before { compare_premium_tuple.age = (base_premium_tuple.age + 2.years) }

        it "should not match" do
          expect(base_premium_tuple).to_not eq compare_premium_tuple
        end

        it "the base_premium_tuple should be less than the compare_premium_tuple" do
          expect(base_premium_tuple <=> compare_premium_tuple).to eq(-1)
        end
      end
    end



  end
end
