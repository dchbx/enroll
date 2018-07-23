require 'rails_helper'

module BenefitMarkets
  RSpec.describe Timespans::DatePeriod, type: :model, dbclean: :after_each do
    let(:this_year)     { TimeKeeper.date_of_record.year }
    let(:begin_on)      { Date.new(this_year, 1, 1) }
    let(:end_on)        { Date.new(this_year, 12, 31) }

    let(:params) do
      {
        begin_on:   begin_on,
        end_on:     end_on,
      }
    end

    context "A new BenefitPeriod instance" do
      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do
        context "that's missing begin_on" do
          subject { described_class.new(params.except(:begin_on)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:begin_on]).to include("can't be blank")
          end
        end

        context "that's missing end_on" do
          subject { described_class.new(params.except(:end_on)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:end_on]).to include("can't be blank")
          end
        end
      end

      context "with invalid params" do
        context "and end_on preceeds begin_on" do
          let(:invalid_end_on)  { begin_on - 1.day }

          subject { described_class.new(params) }
          before { subject.end_on = invalid_end_on }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:begin_on].first).to match(/must be earlier than End on/)
          end
        end
      end

      context "with all valid params" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        context "and it's saved" do

          it "should be findable" do
            subject.save!
            expect(described_class.find(subject.id)).to eq subject
          end
        end
      end
    end

    describe "class methods", dbclean: :after_each do
      context ".find_on" do
        let(:next_year)         { TimeKeeper.date_of_record.year + 1 }
        let(:next_begin_on)     { Date.new(next_year, 1, 1) }
        let(:next_end_on)       { Date.new(next_year, 12, 31) }

        context "with two persisted consecutive periods" do
          let!(:match_period)       { described_class.create!(name: "match_period", begin_on: begin_on, end_on: end_on) }
          let!(:next_match_period)  { described_class.create!(name: "next_match_period", begin_on: next_begin_on, end_on: next_end_on) }

          it "should have exactly 2 date period instances" do
            expect(described_class.all.size).to eq 2
          end

          it "should find each period by matching passed date" do
            expect( BenefitMarkets::Timespans::DatePeriod.find_on(match_period.begin_on).first).to eq match_period
            expect(described_class.find_on(next_match_period.begin_on).first).to eq next_match_period
          end

          it "should return nil for non-matching date", :aggregate_failures do
            expect(described_class.find_on(match_period.begin_on - 1.day)).to eq []
          end
        end
      end
    end


    describe "instance methods" do
      context "#to_range" do
        subject { described_class.new(params) }

        it "should output to range type" do
          expect(subject.to_range).to eq begin_on..end_on
        end
      end

      context "#between?" do
        let(:before_period) { begin_on - 1.day }
        let(:after_period)  { end_on + 1.day }
        let(:during_period) { begin_on + 1.day }

        subject { described_class.new(params) }

        it "before_period should be false" do
          expect(subject.between?(before_period)).to eq false
        end

        it "after_period should be false" do
          expect(subject.between?(after_period)).to eq false
        end

        it "during_period should be true" do
          expect(subject.between?(during_period)).to eq true
        end

        it "begin_on should be true" do
          expect(subject.between?(begin_on)).to eq true
        end

        it "end_on should be true" do
          expect(subject.between?(end_on)).to eq true
        end
      end

    end

  end
end
