# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_product_spec_helpers.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

RSpec.describe BenefitSponsors::Operations::EnrollmentEligibility::Determine, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"

  describe 'for organization with no applications' do

    let!(:abc_organization) do
      org_id = BenefitSponsors::OrganizationSpecHelpers.with_aca_shop_employer_profile(site)
      BenefitSponsors::Organizations::GeneralOrganization.find(org_id)
    end

    let!(:benefit_market_catalog)   { current_benefit_market_catalog }

    let!(:service_area)             { FactoryBot.create_default :benefit_markets_locations_service_area, active_year: TimeKeeper.date_of_record.year }

    let(:abc_profile)               { abc_organization.employer_profile }
    let!(:benefit_sponsorship) do
      benefit_sponsorship = abc_profile.add_benefit_sponsorship
      benefit_sponsorship.aasm_state = :active
      benefit_sponsorship.save

      benefit_sponsorship
    end

    let(:effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:params) do
      {
        effective_date: effective_date,
        benefit_sponsorship: benefit_sponsorship
      }
    end

    let(:result) { subject.call(params) }

    it 'should be success' do
      expect(result.success?).to be_truthy
    end

    it 'should return eligibility_params' do
      expect(result.success[:market_kind]).to eq benefit_sponsorship.market_kind
      expect(result.success[:benefit_application_kind]).to eq 'initial'
      expect(result.success[:effective_date]).to eq effective_date
    end
  end

  describe 'for initial benefit sponsorship' do
    include_context "setup initial benefit application" do
      let(:aasm_state) {ba_aasm_state}
    end

    let(:benefit_sponsorship_params) do
      sponsorship_params = benefit_sponsorship.as_json.symbolize_keys.except(:benefit_applications)
      sponsorship_params[:benefit_applications] = benefit_sponsorship.benefit_applications.collect{|ba| ba.as_json.symbolize_keys.except(:benefit_packages)}
      sponsorship_params[:market_kind] = benefit_sponsorship.market_kind
      sponsorship_params
    end

    let(:benefit_sponsorship_entity) {BenefitSponsors::Operations::BenefitSponsorship::Create.new.call(params: benefit_sponsorship_params).value!}

    let(:effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:params) do
      {
        effective_date: effective_date,
        benefit_sponsorship: benefit_sponsorship_entity
      }
    end
    let(:result) { subject.call(params) }

    context "with termination_pending application" do
      let(:ba_aasm_state) {"termination_pending"}
      it 'should be success' do
        expect(result.success?).to be_truthy
      end

      it 'should return eligibility_params' do
        expect(result.success[:market_kind]).to eq benefit_sponsorship.market_kind
        expect(result.success[:benefit_application_kind]).to eq 'initial'
        expect(result.success[:effective_date]).to eq effective_date
      end
    end

    context "with enrollment_ineligible application" do
      let(:ba_aasm_state) {"enrollment_ineligible"}
      it 'should be success' do
        expect(result.success?).to be_truthy
      end

      it 'should return eligibility_params' do
        expect(result.success[:market_kind]).to eq benefit_sponsorship.market_kind
        expect(result.success[:benefit_application_kind]).to eq 'initial'
        expect(result.success[:effective_date]).to eq effective_date
      end
    end
  end


  describe 'for organization with no applications' do
    include_context 'setup renewal application'

    let(:effective_date) { renewal_effective_date }
    let(:params) do
      {
        effective_date: effective_date,
        benefit_sponsorship: benefit_sponsorship
      }
    end

    let(:result) { subject.call(params) }

    it 'should be success' do
      expect(result.success?).to be_truthy
    end

    it 'should return eligibility_params' do
      expect(result.success[:market_kind]).to eq benefit_sponsorship.market_kind
      expect(result.success[:benefit_application_kind]).to eq 'renewal'
      expect(result.success[:effective_date]).to eq effective_date
    end
  end
end
