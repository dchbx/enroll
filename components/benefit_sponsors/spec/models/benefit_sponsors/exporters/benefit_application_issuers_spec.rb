require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

# Date.today converted to TimeKeeper.date_of_record

module BenefitSponsors
  module Exporters
    RSpec.describe BenefitApplicationIssuers, :dbclean => :after_each do
      include Config::AcaModelConcern
      describe '##retrive' do
        include_context 'setup benefit market with market catalogs and product packages'
        include_context 'setup initial benefit application'

        let!(:health_products) do
          create_list(:benefit_markets_products_health_products_health_product,
                      5, :with_renewal_product, :with_issuer_profile,
                      application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
                      product_package_kinds: [:single_issuer, :metal_level, :single_product],
                      assigned_site: site,
                      service_area: service_area,
                      renewal_service_area: renewal_service_area,
                      metal_level_kind: :gold)
        end

        let(:current_effective_date)  { effective_period_start_on }
        let(:effective_period_end_on) { effective_period_start_on + 1.year - 1.day }
        let(:effective_period)        { effective_period_start_on..effective_period_end_on }

        subject { BenefitSponsors::Exporters::BenefitApplicationIssuers.new }

        context 'of an active employer already transmitted' do
          let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day - 2.month }

          it 'finds the benefit applications' do
            csv_export = BenefitSponsors::Serializers::BenefitApplicationIssuer.to_csv(benefit_sponsorship.benefit_applications.first).first
            expect(subject.lines).to include(csv_export)
          end
        end

        context 'of an renewing employer already transmitted' do
          let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day }
          let(:renewal_state)             { :enrollment_eligible }

          before do
            allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, TimeKeeper.date_of_record.month, aca_shop_market_employer_transmission_day_of_month + 1))
          end

          it 'finds benefit applications' do
            csv_export = BenefitSponsors::Serializers::BenefitApplicationIssuer.to_csv(benefit_sponsorship.benefit_applications.first).first
            expect(subject.lines).to include(csv_export)
          end
        end

        context 'of an renewing employer not yet transmitted' do
          let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day }
          let(:renewal_state)             { :enrollment_eligible }

          before do
            allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, TimeKeeper.date_of_record.month, aca_shop_market_employer_transmission_day_of_month - 1))
          end

          it 'finds benefit applications' do
            csv_export = BenefitSponsors::Serializers::BenefitApplicationIssuer.to_csv(benefit_sponsorship.benefit_applications.first).first
            expect(subject.lines).to include(csv_export)
          end
        end

        context 'of an ineligible application' do
          let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day }
          let(:renewal_state)             { :enrollment_closed }

          before do
            allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, TimeKeeper.date_of_record.month, aca_shop_market_employer_transmission_day_of_month + 1))
          end

          it 'finds benefit applications' do
            csv_export = BenefitSponsors::Serializers::BenefitApplicationIssuer.to_csv(benefit_sponsorship.benefit_applications.effective_date_begin_on(effective_period_start_on).first)
            expect(subject.lines).to_not include(csv_export)
          end
        end
      end
    end
  end
end
