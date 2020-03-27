# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::BenefitMarkets::CreateBenefitSponsorCatalog, dbclean: :after_each do

  let!(:site)          { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :as_hbx_profile, Settings.site.key) }
  let(:benefit_market) { site.benefit_markets.first }
  let(:effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:market_kind)    { :aca_shop }
  let(:service_areas)  { FactoryBot.create(:benefit_markets_locations_service_area).to_a }
  let(:params)         { {service_areas: service_areas, enrollment_eligibility: double(effective_date: effective_date, market_kind: market_kind, benefit_application_kind: :initial)} }

  context 'sending required parameters' do

    it 'should create BenefitSponsorCatalog' do
      expect(subject.call(params).success?).to be_truthy
      expect(subject.call(params).success).to be_a BenefitMarkets::Entities::BenefitSponsorCatalog
    end
  end
end
