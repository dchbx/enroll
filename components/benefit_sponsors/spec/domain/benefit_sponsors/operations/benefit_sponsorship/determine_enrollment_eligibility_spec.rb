# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_product_spec_helpers.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

RSpec.describe BenefitSponsors::Operations::BenefitSponsorship::DetermineEnrollmentEligibility, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"

  describe 'for organization with no applications' do

    include_context "setup initial benefit application"

    let(:effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:params) do
      {
        effective_date: effective_date,
        benefit_sponsorship_id: benefit_sponsorship.id
      }
    end

    let(:result) { subject.call(params) }

    before :each do
      benefit_sponsorship.benefit_applications.delete_all
    end

    it 'should return enrollment eligibility' do
      expect(result.success?).to be_truthy
    end

    it 'should return enrollment eligibility entity' do
      expect(result.success).to be_a BenefitSponsors::Entities::EnrollmentEligibility
    end

    it 'should return eligibility type' do
      expect(result.success.benefit_application_kind).to eq :initial
    end
  end

  shared_examples_for "enrollment eligibility determination" do |aasm_state, status, benefit_application_start_date, eligibility_date|
    describe "#{aasm_state} application" do

      include_context "setup initial benefit application"

      let(:current_effective_date) { benefit_application_start_date || TimeKeeper.date_of_record.next_month.beginning_of_month }
      let(:aasm_state) { aasm_state }
      let(:params) do
        {
          effective_date: eligibility_date,
          benefit_sponsorship_id: benefit_sponsorship.id
        }
      end

      let(:result) { subject.call(params) }

      it 'should return enrollment eligibility' do
        expect(result.success?).to be_truthy
      end

      it 'should return enrollment eligibility entity' do
        expect(result.success).to be_a BenefitSponsors::Entities::EnrollmentEligibility
      end

      it 'should return eligibility type' do
        expect(result.success.benefit_application_kind).to eq status
      end
    end
  end

  describe 'for initial organizations' do
    [TimeKeeper.date_of_record.next_month.beginning_of_month, (TimeKeeper.date_of_record + 2.months).beginning_of_month, (TimeKeeper.date_of_record + 3.months).beginning_of_month].each do |eligibility_date|
      it_behaves_like "enrollment eligibility determination", "draft", :initial, nil, eligibility_date
      it_behaves_like "enrollment eligibility determination", "enrollment_open", :initial, nil, eligibility_date
      it_behaves_like "enrollment eligibility determination", "enrollment_closed", :initial, nil, eligibility_date
      it_behaves_like "enrollment eligibility determination", "binder_paid", :initial, nil, eligibility_date
      it_behaves_like "enrollment eligibility determination", "enrollment_eligible", :initial, nil, eligibility_date
      it_behaves_like "enrollment eligibility determination", "enrollment_ineligible", :initial, nil, eligibility_date
      it_behaves_like "enrollment eligibility determination", "canceled", :initial, nil, eligibility_date
    end
  end

  describe 'for organization with active application' do
    # gap in coverage case
    it_behaves_like "enrollment eligibility determination", "active", :initial, TimeKeeper.date_of_record.beginning_of_month.prev_year, TimeKeeper.date_of_record.beginning_of_month.prev_year.next_year.next_month
  end


  describe 'for organizaton with off-cycle application' do
    it_behaves_like "enrollment eligibility determination", "active", :initial, TimeKeeper.date_of_record.beginning_of_month.prev_year, TimeKeeper.date_of_record.beginning_of_month.prev_year.next_year.prev_month
  end

  describe 'for renewing application' do
    it_behaves_like "enrollment eligibility determination", "active", :renewal, TimeKeeper.date_of_record.beginning_of_month.prev_year, TimeKeeper.date_of_record.beginning_of_month.prev_year.next_year
  end
end

