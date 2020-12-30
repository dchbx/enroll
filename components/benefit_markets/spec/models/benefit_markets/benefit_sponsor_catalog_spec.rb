require 'rails_helper'

module BenefitMarkets
  RSpec.describe BenefitSponsorCatalog, type: :model, dbclean: :after_each do
    let(:subject) { described_class.new }

    let(:this_year)               { Date.today.year }
    let(:application_period)      { Date.new(this_year,1,1)..Date.new(this_year,12,31) }
    let(:effective_date)          { Date.new(this_year, 6,1) }
    let(:effective_period)        { effective_date..(effective_date + 1.year - 1.day) }
    let(:open_enrollment_period)  { (effective_date - 1.month)..(effective_date - 1.month + 9.days) }
    let(:probation_period_kinds)  { [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days] }
    let(:service_areas)           { FactoryBot.build(:benefit_markets_locations_service_area).to_a }
    let(:sponsor_market_policy)   { BenefitMarkets::MarketPolicies::SponsorMarketPolicy.new }
    let(:member_market_policy)    { BenefitMarkets::MarketPolicies::MemberMarketPolicy.new }
    let(:product_packages)        { [FactoryBot.build(:benefit_markets_products_product_package)] }

    let(:params) do
      {
        effective_date:         effective_date,
        effective_period:       effective_period,
        open_enrollment_period: open_enrollment_period,
        probation_period_kinds: probation_period_kinds,
        service_areas:          service_areas,
        sponsor_market_policy:  sponsor_market_policy,
        member_market_policy:   member_market_policy,
        product_packages:       product_packages,
      }
    end

    # Mocking benefit application in order to avoid adding models to the dummy
    before :each do
      allow_any_instance_of(BenefitMarkets::BenefitSponsorCatalog).to receive(:benefit_application).and_return nil
    end

    context "A new model instance" do

     # it { is_expected.to be_mongoid_document }
     # it { is_expected.to have_fields(:effective_date, :effective_period, :open_enrollment_period) }
     # it { is_expected.to have_field(:probation_period_kinds).of_type(Array).with_default_value_of([]) }

     # it { is_expected.to embeds_one(:sponsor_market_policy) }
     # it { is_expected.to embeds_one(:member_market_policy) }
     # it { is_expected.to embeds_many(:benefit_packages) }
     # it { is_expected.to belongs_to(:service_area) }

      context "with no effective_date" do
        subject { described_class.new(params.except(:effective_date)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no effective_period" do
        subject { described_class.new(params.except(:effective_period)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no open_enrollment_period" do
        subject { described_class.new(params.except(:open_enrollment_period)) }

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

      context "with no service_area" do
        subject { described_class.new(params.except(:service_areas)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end


 # TODO Fix -- re-enable when seed file supports these
      # context "with no sponsor_market_policy" do
      #   subject { described_class.new(params.except(:sponsor_market_policy)) }

      #   it "should not be valid" do
      #     subject.validate
      #     expect(subject).to_not be_valid
      #   end
      # end

      # context "with no member_market_policy" do
      #   subject { described_class.new(params.except(:member_market_policy)) }

      #   it "should not be valid" do
      #     subject.validate
      #     expect(subject).to_not be_valid
      #   end
      # end

      context "with no product_packages" do
        subject { described_class.new(params.except(:product_packages)) }

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

    context "Comparing catalogs" do
      let(:base_catalog)                 { described_class.new(**params) }

      context "and they are the same" do
        let(:compare_catalog)              { described_class.new(**params) }

        it "they should be different instances" do
          expect(base_catalog.id).to_not eq compare_catalog.id
        end

        it "should match" do
          expect(base_catalog <=> compare_catalog).to eq 0
          # expect(base_catalog.attributes.except(:_id)).to eq compare_catalog.attributes.except(:_id)
        end
      end

      context "and the attributes are different" do
        let(:compare_catalog)              { described_class.new(**params) }

        before { compare_catalog.effective_date = effective_date + 1.month }

        it "should not match" do
          expect(base_catalog).to_not eq compare_catalog
        end

        it "the base_catalog should be less than the compare_catalog" do
          expect(base_catalog <=> compare_catalog).to eq -1
        end
      end

      context "and the product_packages are different", dbclean: :after_each do
        let(:compare_catalog)     { described_class.new(**params) }
        let(:new_product_package) { FactoryBot.build(:benefit_markets_products_product_package) }

        before { compare_catalog.product_packages << new_product_package }

        it "should not match" do
          expect(base_catalog).to_not eq compare_catalog
        end

        it "the base_catalog should be lest than the compare_catalog" do
          expect(base_catalog <=> compare_catalog).to eq -1
        end
      end
    end

  end
end
