# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::BenefitMarketCatalogs::FindModel, dbclean: :after_each do

  let(:site)           { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :with_benefit_market_catalog_and_product_packages, Settings.site.key) }
  let!(:benefit_market) { site.benefit_markets.first }
  let(:effective_date) { TimeKeeper.date_of_record.beginning_of_month }
  let(:market_kind)    { :aca_shop }
  let(:params)         { {effective_date: effective_date, market_kind: market_kind} }
  let(:instance)       { benefit_market.benefit_market_catalog_for(effective_date) }

  context 'sending required parameters' do

    it 'should find BenefitMarketCatalog instance' do
      expect(subject.call(params).success?).to be_truthy
      expect(subject.call(params).success).to be_a BenefitMarkets::BenefitMarketCatalog
    end

    it 'should return object' do
      expect(subject.call(params).success).to eq instance
    end
  end
end
