# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe Serializers::BenefitApplicationIssuer, dbclean: :around_each do
    describe "##to_csv(benefit_application)" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

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

      let(:package_kind)            { :metal_level }

      let(:current_effective_date) { effective_period_start_on }
      let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
      let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
      let(:effective_period)          { effective_period_start_on..effective_period_end_on }

      let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
      let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      subject { BenefitSponsors::Serializers::BenefitApplicationIssuer.to_csv(benefit_sponsorship.benefit_applications.first) }

      it 'returns a csv line for each carrier' do
        all_records = product_package.products.map(&:issuer_profile).map do |issuer_profile|
          [abc_organization.hbx_id,
           abc_organization.fein,
           effective_period_start_on.strftime('%Y-%m-%d'),
           effective_period_end_on.strftime('%Y-%m-%d'),
           issuer_profile.hbx_carrier_id,
           issuer_profile.fein].join(',')
        end
        expect(subject).to eq(all_records)
      end

      it 'serializes the date to ISO 8601' do
        date_field = subject.first.split(',').third
        expect(Date.strptime(date_field, '%Y-%m-%d')).to eq(effective_period_start_on)
      end
    end
  end
end
