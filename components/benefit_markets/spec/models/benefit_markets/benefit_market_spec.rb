# frozen_string_literal: true

require 'rails_helper'

module BenefitMarkets
  RSpec.describe BenefitMarket, type: :model, dbclean: :after_each do

    let(:kind)            { :aca_shop }
    let(:site_urn)        { 'dc' }
    let(:title)           {  "DC Health Link SHOP Market" }
    let(:description)     {  "Health Insurance Marketplace for District Employers and Employees" }
    let(:configuration)   { build :benefit_markets_aca_shop_configuration }

    let(:params) do
      {
        kind: kind,
        site_urn: site_urn,
        title: title,
        description: description,
        configuration: configuration
      }
    end

    context "a new model instance" do
      context "with no arguments" do
        let(:benefit_market) { BenefitMarkets::BenefitMarket.new }

        it "should not be valid" do
          benefit_market.validate
          expect(benefit_market).to_not be_valid
        end
      end

      context "with no kind attribute" do
        let(:benefit_market) { BenefitMarkets::BenefitMarket.new(params.except(:kind)) }

        it "should not be valid" do
          benefit_market.validate
          expect(benefit_market).to_not be_valid
        end
      end

      context "with invalid kind attribute" do
        let(:invalid_kind)    { :corner_market }
        let(:benefit_market)  { BenefitMarkets::BenefitMarket.new(kind: invalid_kind) }

        it "should not be valid" do
          benefit_market.validate
          expect(benefit_market).to_not be_valid
          expect(benefit_market.errors[:kind].first).to match(/is not a valid market kind/)
        end
      end

      context "with valid kind attribute" do
        let(:valid_kind)        { :aca_shop }
        let(:benefit_market)    { BenefitMarkets::BenefitMarket.new(params) }
        let(:valid_class_name)  { "BenefitMarkets::AcaShopConfiguration" }

        before { benefit_market.kind = valid_kind  }

        it "should set a kind-appropropriate configuration setting" do
          expect(benefit_market.kind).to eq valid_kind
          # TODO: Enable following matcher when configuration assocation enabled.
          #       Currently its disabled due to errors on instantiate
          # expect(benefit_market.configuration.class.to_s).to eq valid_class_name
          # expect(BenefitMarkets::BenefitMarket.new(kind: shop_kind).configuration_setting.class).to eq configuration_setting_class
          # expect(benefit_market.configuration_setting.class).to eq configuration_setting_class
        end
      end

      context "with all required arguments", dbclean: :after_each do
        let(:valid_benefit_market)  { BenefitMarkets::BenefitMarket.new(params) }

        it "all provided attributes should be set" do
          expect(valid_benefit_market.kind).to eq kind
          expect(valid_benefit_market.site_urn).to eq site_urn
          expect(valid_benefit_market.title).to eq title
          expect(valid_benefit_market.description).to eq description
        end

        it "should be valid" do
          valid_benefit_market.validate
          expect(valid_benefit_market).to be_valid
        end

        it "should save and be findable" do
          expect(valid_benefit_market.save!).to eq true
          expect(BenefitMarkets::BenefitMarket.find(valid_benefit_market.id)).to eq valid_benefit_market
        end

      end
    end

    context "with benefit_market_catalogs" do
      let(:benefit_market)                  { BenefitMarkets::BenefitMarket.new(kind: kind, title: title, description: description) }

      let(:today)                           { Date.today }
      let(:this_year_range)                 { Date.new(today.year,1,1)..Date.new(today.year,12,31) }
      let(:last_year_range)                 { (this_year_range.begin - 1.year)..(this_year_range.end - 1.year)}
      let(:next_year_range)                 { (this_year_range.begin + 1.year)..(this_year_range.end + 1.year)}

      let(:last_year_benefit_market_catalog)  { FactoryBot.build(:benefit_markets_benefit_market_catalog, application_period: this_year_range) }
      let(:this_year_benefit_market_catalog)  { FactoryBot.build(:benefit_markets_benefit_market_catalog, application_period: last_year_range) }
      let(:next_year_benefit_market_catalog)  { FactoryBot.build(:benefit_markets_benefit_market_catalog, application_period: next_year_range) }
      let(:same_year_benefit_market_catalog)  { FactoryBot.build(:benefit_markets_benefit_market_catalog, application_period: this_year_range) }

      it "should add a benefit_market_catalog" do
        benefit_market.add_benefit_market_catalog(this_year_benefit_market_catalog)
        expect(benefit_market.benefit_market_catalogs.size).to eq 1
        expect(benefit_market.benefit_market_catalogs).to include this_year_benefit_market_catalog
      end

      it "should block addition of benefit_market_catalogs with same date range" do
        benefit_market.add_benefit_market_catalog(this_year_benefit_market_catalog)
        # expect(benefit_market.add_benefit_market_catalog(same_year_benefit_market_catalog)).not_to include same_year_benefit_market_catalog
      end

    end

    # context "benefit_market should be findable by kind" do
    #   let(:shop_kind)           { :aca_shop }
    #   let(:individual_kind)     { :aca_individual }
    #   let!(:shop_site)          { create(:sponsored_benefits_site, :with_owner_exempt_organization, :with_benefit_market, kind: shop_kind) }
    #   let!(:individual_site)    { create(:sponsored_benefits_site, :with_owner_exempt_organization, :with_benefit_market, kind: individual_kind) }

    #   let(:found_sites)         { Site.by_benefit_market_kind(shop_kind) }

    #   it "should find the shop site and only the shop" do
    #     expect(found_sites.size).to eq 1
    #     expect(found_sites.first).to eq shop_site
    #   end

    #   it "should have the queried benefit_market_kind" do
    #     expect(found_sites.first.benefit_markets.first.kind).to eq shop_kind
    #   end
    # end

  end
end
