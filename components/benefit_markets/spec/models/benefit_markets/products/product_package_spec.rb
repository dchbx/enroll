require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::ProductPackage, type: :model, db_clean: :after_each do

    let(:this_year)               { TimeKeeper.date_of_record.year }
    # let(:benefit_market_kind)     { :aca_shop }

    let(:benefit_market_catalog)  { FactoryGirl.build(:benefit_markets_benefit_market_catalog) }
    let(:benefit_kind)            { :aca_shop }
    let(:product_kind)            { :health }
    let(:package_kind)            { :single_issuer }
    let(:title)                   { "SafeCo Issuer Health" }
    let(:description)             { "All products offered by a single issuer" }
    let(:products)                { FactoryGirl.build_list(:benefit_markets_products_product, 5) }
    let(:contribution_model)      { FactoryGirl.build(:benefit_markets_contribution_models_contribution_model) }
    let(:pricing_model)           { FactoryGirl.build(:benefit_markets_pricing_models_pricing_model) }


    let(:params) do
        {
          benefit_kind:           benefit_kind,
          product_kind:           product_kind,
          package_kind:           package_kind,
          title:                  title,
          description:            description,
          products:               products,
          application_period:     benefit_market_catalog.application_period,
          contribution_model:     contribution_model,
          pricing_model:          pricing_model,
        }
    end

    context "A new model instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do

        # context "that's missing benefit_market_catalog" do
        #   subject { described_class.new(params.except(:benefit_market_catalog)) }

        #   it "should be invalid" do
        #     subject.validate
        #     expect(subject).to_not be_valid
        #     expect(subject.errors[:benefit_market_catalog]).to include("can't be blank")
        #   end
        # end

        context "that's missing title" do
          subject { described_class.new(params.except(:title)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:title]).to include("can't be blank")
          end
        end

        context "that's missing product_kind" do
          subject { described_class.new(params.except(:product_kind)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:product_kind]).to include("can't be blank")
          end
        end

        context "that's missing kind" do
          subject { described_class.new(params.except(:package_kind)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:package_kind]).to include("can't be blank")
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

    context "Comparing Product Packages" do
      let(:base_product_package)      { described_class.new(**params) }

      context "and they are the same" do
        let(:compare_product_package) { described_class.new(**params) }

        it "they should be different instances" do
          expect(base_product_package.id).to_not eq compare_product_package.id
        end

        it "should match" do
          expect(base_product_package <=> compare_product_package).to eq 0
          expect(base_product_package.attributes.except('_id')).to eq compare_product_package.attributes.except('_id')
        end
      end

      context "and the attributes are different" do
        let(:compare_product_package)              { described_class.new(**params) }

        before { compare_product_package.product_kind = :dental }

        it "should not match" do
          expect(base_product_package).to_not eq compare_product_package
        end

        it "the base_product_package should be less than the compare_product_package" do
          expect(base_product_package <=> compare_product_package).to eq -1
        end
      end

      context "and the product_packages are different" do
        let(:compare_product_package)     { described_class.new(**params) }
        let(:new_product)                 { FactoryGirl.build(:benefit_markets_products_product) }

        before { compare_product_package.products << new_product }

        it "should not match" do
          expect(base_product_package).to_not eq compare_product_package
        end

        it "the base_product_package should be lest than the compare_product_package" do
          expect(base_product_package <=> compare_product_package).to eq -1
        end
      end
    end


  end
end
