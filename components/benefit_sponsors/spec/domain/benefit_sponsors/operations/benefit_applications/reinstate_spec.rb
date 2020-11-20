# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::Operations::BenefitApplications::Reinstate, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end

  let!(:effective_period_start_on) { TimeKeeper.date_of_record.beginning_of_year }
  let!(:effective_period_end_on)   { TimeKeeper.date_of_record.end_of_year }
  let!(:site) { BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }
  let!(:benefit_market) { site.benefit_markets.first }
  let!(:effective_period) { (effective_period_start_on..effective_period_end_on) }
  let!(:current_benefit_market_catalog) do
    BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_catalog(site, benefit_market, effective_period)
    benefit_market.benefit_market_catalogs.where(
      "application_period.min" => effective_period_start_on
    ).first
  end

  let!(:service_areas) do
    ::BenefitMarkets::Locations::ServiceArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).all.to_a
  end

  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).first
  end
  let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_year}

  include_context 'setup initial benefit application'

  context 'with valid benefit_application' do
    let(:current_year) {current_effective_date.year}
    let(:end_of_the_year) {Date.new(current_year, 12, 31)}

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 10, 15))
      initial_application.benefit_packages.each do |bp|
        bp.sponsored_benefits.each do |spon_benefit|
          spon_benefit.update_attributes!(_type: 'BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit')
          create_pd(spon_benefit)
          update_contribution_levels(spon_benefit)
        end
      end
    end

    context 'success' do
      context 'reinstate terminated benefit application' do
        before do
          initial_application.terminate_enrollment!
          initial_application.update_attributes!(termination_reason: 'Testing', terminated_on: (TimeKeeper.date_of_record - 1.month).end_of_month)
          @new_ba = subject.call({benefit_application: initial_application}).success
          @first_wfst = @new_ba.workflow_state_transitions.first
          @second_wfst = @new_ba.workflow_state_transitions.second
        end

        it 'should return a success with a BenefitApplication' do
          expect(@new_ba).to be_a(BenefitSponsors::BenefitApplications::BenefitApplication)
        end

        it 'should return a BenefitApplication with aasm_state active' do
          expect(@new_ba.aasm_state).to eq(:active)
        end

        it 'should return a BenefitApplication with remaining effective_period' do
          expect(@new_ba.effective_period).to eq((initial_application.terminated_on + 1.day)..end_of_the_year)
        end

        it 'should populate reinstated_id' do
          expect(@new_ba.reinstated_id).to eq(initial_application.id)
        end

        it 'should create new benefit_sponsor_catalog' do
          expect(@new_ba.benefit_sponsor_catalog_id).not_to eq(initial_application.benefit_sponsor_catalog_id)
        end

        context 'workflow_state_transitions' do
          it 'should record transition from_state' do
            expect(@first_wfst.from_state).to eq('draft')
          end

          it 'should record transition to_state' do
            expect(@first_wfst.to_state).to eq('reinstated')
          end

          it 'should record transition from_state' do
            expect(@second_wfst.from_state).to eq('reinstated')
          end

          it 'should record transition to_state' do
            expect(@second_wfst.to_state).to eq('active')
          end
        end
      end

      context 'reinstate canceled benefit application' do
        before do
          initial_application.cancel!
          @new_ba = subject.call({benefit_application: initial_application}).success
          @first_wfst = @new_ba.workflow_state_transitions.first
          @second_wfst = @new_ba.workflow_state_transitions.second
        end

        it 'should return a BenefitApplication with aasm_state active' do
          expect(@new_ba.aasm_state).to eq(:active)
        end

        it 'should return a BenefitApplication with matching effective_period' do
          expect(@new_ba.effective_period).to eq(initial_application.effective_period)
        end

        it 'should populate reinstated_id' do
          expect(@new_ba.reinstated_id).to eq(initial_application.id)
        end

        it 'should create new benefit_sponsor_catalog' do
          expect(@new_ba.benefit_sponsor_catalog_id).not_to eq(initial_application.benefit_sponsor_catalog_id)
        end

        context 'workflow_state_transitions' do
          it 'should record transition from_state' do
            expect(@first_wfst.from_state).to eq('draft')
          end

          it 'should record transition to_state' do
            expect(@first_wfst.to_state).to eq('reinstated')
          end

          it 'should record transition from_state' do
            expect(@second_wfst.from_state).to eq('reinstated')
          end

          it 'should record transition to_state' do
            expect(@second_wfst.to_state).to eq('active')
          end
        end
      end

      context 'reinstate termination_pending benefit application' do
        before do
          initial_application.schedule_enrollment_termination!
          initial_application.update_attributes!(termination_reason: 'Testing, future termination', terminated_on: TimeKeeper.date_of_record.end_of_month)
          @new_ba = subject.call({benefit_application: initial_application}).success
          @first_wfst = @new_ba.workflow_state_transitions.first
          @second_wfst = @new_ba.workflow_state_transitions.second
        end

        it 'should return a success with a BenefitApplication' do
          expect(@new_ba).to be_a(BenefitSponsors::BenefitApplications::BenefitApplication)
        end

        it 'should return a BenefitApplication with aasm_state active' do
          expect(@new_ba.aasm_state).to eq(:active)
        end

        it 'should return a BenefitApplication with remaining effective_period' do
          expect(@new_ba.effective_period).to eq((initial_application.terminated_on + 1.day)..end_of_the_year)
        end

        it 'should populate reinstated_id' do
          expect(@new_ba.reinstated_id).to eq(initial_application.id)
        end

        it 'should create new benefit_sponsor_catalog' do
          expect(@new_ba.benefit_sponsor_catalog_id).not_to eq(initial_application.benefit_sponsor_catalog_id)
        end

        context 'workflow_state_transitions' do
          it 'should record transition from_state' do
            expect(@first_wfst.from_state).to eq('draft')
          end

          it 'should record transition to_state' do
            expect(@first_wfst.to_state).to eq('reinstated')
          end

          it 'should record transition from_state' do
            expect(@second_wfst.from_state).to eq('reinstated')
          end

          it 'should record transition to_state' do
            expect(@second_wfst.to_state).to eq('active')
          end
        end
      end
    end

    context 'with overlapping benefit_application' do
      context "new effective_on lies within a benefit_application's effective_period" do
        before do
          overlapping_ba = initial_application.benefit_sponsorship.benefit_applications.new
          initial_app_params = initial_application.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :benefit_packages, :workflow_state_transitions)
          overlapping_ba.assign_attributes(initial_app_params)
          overlapping_ba.save!
          initial_application.terminate_enrollment!
          initial_application.update_attributes!(termination_reason: 'Testing', terminated_on: (TimeKeeper.date_of_record - 1.month).end_of_month)
          @result = subject.call({benefit_application: initial_application})
        end

        it 'should return failure with a message' do
          expect(@result.failure).to eq('Overlapping BenefitApplication exists for this Employer.')
        end
      end

      context 'a valid benefit_application will be effective after the new effective_on' do
        before do
          overlapping_ba = initial_application.benefit_sponsorship.benefit_applications.new
          initial_app_params = initial_application.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :benefit_packages, :workflow_state_transitions)
          overlapping_ba.assign_attributes(initial_app_params)
          ba_effective_period = (Date.new(current_year, 12, 1)..end_of_the_year)
          overlapping_ba.assign_attributes(effective_period: ba_effective_period)
          overlapping_ba.save!
          initial_application.terminate_enrollment!
          initial_application.update_attributes!(termination_reason: 'Testing', terminated_on: (TimeKeeper.date_of_record - 1.month).end_of_month)
          @result = subject.call({benefit_application: initial_application})
        end

        it 'should return failure with a message' do
          expect(@result.failure).to eq('Overlapping BenefitApplication exists for this Employer.')
        end
      end
    end
  end

  context 'failure' do
    context 'no params' do
      before do
        @result = subject.call({})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing Key.')
      end
    end

    context 'invalid params' do
      before do
        @result = subject.call({benefit_application: 'benefit_application'})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Not a valid Benefit Application object.')
      end
    end

    context "invalid benefit_application's aasm state" do
      before do
        @result = subject.call({benefit_application: initial_application})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Given BenefitApplication is not in any of the [:terminated, :termination_pending, :canceled] states.')
      end
    end
  end
end

def create_pd(spon_benefit)
  pricing_determination = BenefitSponsors::SponsoredBenefits::PricingDetermination.new({group_size: 4, participation_rate: 75})
  spon_benefit.pricing_determinations << pricing_determination
  pricing_unit_id = spon_benefit.product_package.pricing_model.pricing_units.first.id
  pricing_determination_tier = BenefitSponsors::SponsoredBenefits::PricingDeterminationTier.new({pricing_unit_id: pricing_unit_id, price: 320.00})
  pricing_determination.pricing_determination_tiers << pricing_determination_tier
  spon_benefit.save!
end

def update_contribution_levels(spon_benefit)
  spon_benefit.sponsor_contribution.contribution_levels.each do |cl|
    cl.update_attributes!({contribution_cap: 0.5, flat_contribution_amount: 100.00})
  end
end
