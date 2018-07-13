require 'rails_helper'

module BenefitMarkets
  RSpec.describe BenefitMarketCatalog, type: :model, dbclean: :after_each do

    let(:benefit_market_kind)       { :aca_shop }
    let(:today)                     { Date.today }

    let(:title)                     { "Benefit Buddy's SHOP Employer Benefit Market" }
    let(:description)               { "As an eligible employer, you may shop, select, and elect contribution amounts on \
                                      benefit products that you make available for your employees to purchase." }
    let(:benefit_market)            { BenefitMarkets::BenefitMarket.new(kind: benefit_market_kind)  }
    let(:application_interval_kind) { :monthly }
    let(:application_period)        { Date.new(today.year, 1, 1)..Date.new(today.year, 12, 31) }
    let(:probation_period_kinds)    { [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days] }


    let(:params) do
      {
        benefit_market: benefit_market,
        application_interval_kind: application_interval_kind,
        application_period: application_period,
        probation_period_kinds: probation_period_kinds,
        title: title,
        description: description,
      }
    end

    context "A new model instance" do

      context "with no benefit_market" do
        subject { described_class.new(params.except(:benefit_market)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no application_interval_kind" do
        subject { described_class.new(params.except(:application_interval_kind)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no application_period" do
        subject { described_class.new(params.except(:application_period)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no probation_period_kinds" do
        subject { described_class.new(params.except(:probation_period_kinds)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with an invalid probation_period_kinds" do
        subject { described_class.new(params) }
        let(:invalid_kind)                    { :after_termination }
        let(:invalid_probation_period_kinds)  { probation_period_kinds << invalid_kind }

        before { subject.probation_period_kinds = invalid_probation_period_kinds }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
          expect(subject.errors.messages[:probation_period_kinds].first).to match(/#{invalid_kind} is not a valid probation period kind/)
        end
      end

      context "with all required arguments" do
        subject { described_class.new(params) }

        context "and all arguments are valid" do

          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end

          it "should save and be findable" do
            expect(subject.save!).to eq true
            expect(BenefitMarkets::BenefitMarketCatalog.find(subject.id)).to eq subject
          end

          it "should be updateable" do
            expect{subject.update_attributes!(title: "New Title")}.to_not raise_error
          end
        end
      end
    end

    context "A benefit catalog with application period overlapping an existing catalog" do
      let(:period_with_same_start_date)         { application_period.min..(application_period.max + 1.day) }
      let(:period_with_same_end_date)           { (application_period.min - 1.day)..application_period.max }
      let(:period_with_overlapping_start_date)  { (application_period.min + 1.month)..(application_period.max + 1.month) }
      let(:period_with_overlapping_end_date)    { (application_period.min - 1.month)..(application_period.max - 1.month) }

      let!(:existing_catalog)                   { described_class.create(**params) }
      let(:conflicting_catalog)                 { described_class.new(params.except(:application_period)) }


      context "with same start date" do
        before { conflicting_catalog.application_period = period_with_same_start_date }

        it "should be invalid" do
          conflicting_catalog.validate
          expect(conflicting_catalog).to_not be_valid
          expect(conflicting_catalog.errors.messages[:application_period].first).to match(/already exists for dates/)
        end
      end

      context "with same end date" do
        before { conflicting_catalog.application_period = period_with_same_end_date }

        it "should be invalid" do
          conflicting_catalog.validate
          expect(conflicting_catalog).to_not be_valid
          expect(conflicting_catalog.errors.messages[:application_period].first).to match(/already exists for dates/)
        end
      end

      context "with overlapping start date" do
        before { conflicting_catalog.application_period = period_with_overlapping_start_date }

        it "should be invalid" do
          conflicting_catalog.validate
          expect(conflicting_catalog).to_not be_valid
          expect(conflicting_catalog.errors.messages[:application_period].first).to match(/already exists for dates/)
        end
      end

      context "with overlapping end date" do
        before { conflicting_catalog.application_period = period_with_overlapping_end_date }

        it "should be invalid" do
          conflicting_catalog.validate
          expect(conflicting_catalog).to_not be_valid
          expect(conflicting_catalog.errors.messages[:application_period].first).to match(/already exists for dates/)
        end
      end

    end


  end
end
