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
  let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
  let(:family) { person.primary_family }
  let!(:census_employee) do
    ce = FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
    ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
    person.employee_roles.first.update_attributes(census_employee_id: ce.id)
    ce
  end
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                      household: family.latest_household,
                      coverage_kind: 'health',
                      family: family,
                      aasm_state: 'coverage_selected',
                      effective_on: current_effective_date,
                      kind: 'employer_sponsored',
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: census_employee.employee_role.id,
                      product: current_benefit_package.sponsored_benefits[0].reference_product,
                      rating_area_id: BSON::ObjectId.new,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end


  context 'with valid benefit_application' do
    let(:current_year) {current_effective_date.year}
    let(:end_of_the_year) {Date.new(current_year, 12, 31)}

    before do
      load_cache
      setup_contribution_models(benefit_sponsor_catalog)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 10, 1))
      initial_application.benefit_packages.each do |bp|
        bp.sponsored_benefits.each do |spon_benefit|
          spon_benefit.update_attributes!(_type: 'BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit')
          create_pd(spon_benefit)
          update_contribution_levels(spon_benefit) if initial_application.employer_profile.is_a_fehb_profile?
        end
      end
    end

    context 'success' do
      context 'reinstate terminated benefit application' do
        before do
          period = initial_application.effective_period.min..(initial_application.effective_period.min.next_month.next_month.next_month.prev_day)
          initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: (TimeKeeper.date_of_record - 1.month).end_of_month, effective_period: period)
          initial_application.terminate_enrollment!
          @new_ba = subject.call({params: {benefit_application: initial_application}}).success
          @first_wfst = @new_ba.workflow_state_transitions.first
          @second_wfst = @new_ba.workflow_state_transitions.second
          census_employee.reload
        end

        it 'should return a success with a BenefitApplication' do
          expect(@new_ba).to be_a(BenefitSponsors::BenefitApplications::BenefitApplication)
        end

        it 'should return a BenefitApplication with aasm_state active' do
          expect(@new_ba.aasm_state).to eq(:active)
        end

        it 'should return a BenefitApplication with remaining effective_period' do
          expect(@new_ba.effective_period).to eq((initial_application.effective_period.max.next_day)..end_of_the_year)
        end

        it 'should populate reinstated_id' do
          expect(@new_ba.reinstated_id).to eq(initial_application.id)
        end

        it 'should reinstate benefit group assignment' do
          reinstated_bga = census_employee.benefit_group_assignments.where(:benefit_package_id.in => @new_ba.benefit_packages.map(&:id)).first
          expect(reinstated_bga.start_on).to eq(@new_ba.start_on)
        end

        it 'should reinstate enrollment' do
          reinstated_enrollment = HbxEnrollment.where(:sponsored_benefit_package_id.in => @new_ba.benefit_packages.map(&:id)).first
          expect(reinstated_enrollment.effective_on).to eq(@new_ba.start_on)
          expect(reinstated_enrollment.predecessor_enrollment_id).to eq(enrollment.id)
        end

        it 'should create new benefit_sponsor_catalog' do
          expect(@new_ba.benefit_sponsor_catalog_id).not_to eq(initial_application.benefit_sponsor_catalog_id)
          expect(@new_ba.benefit_sponsor_catalog.benefit_application).to eq(@new_ba)
          expect(@new_ba.benefit_sponsor_catalog.benefit_application.persisted?).to be_truthy
        end

        it 'should create a renewal draft for the reinstated benefit_application' do
          expect(@new_ba.benefit_sponsorship.benefit_applications.count).to eq(3)
          expect(@new_ba.benefit_sponsorship.benefit_applications.last.aasm_state).to eq(:draft)
        end

        it 'should renew benefit group assignment for renewing draft application' do
          renewing_app = benefit_sponsorship.renewal_benefit_application
          renewing_bga = census_employee.benefit_group_assignments.where(:benefit_package_id.in => renewing_app.benefit_packages.map(&:id)).first
          expect(renewing_bga.start_on).to eq renewing_app.start_on
        end

        context 'workflow_state_transitions' do
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

      context 'reinstate retro active canceled benefit application' do
        before do
          initial_application.cancel!
          @new_ba = subject.call({params: {benefit_application: initial_application}}).success
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

      context 'reinstate active to canceled state benefit application' do
        before do
          initial_application.aasm_state = :canceled
          initial_application.workflow_state_transitions.new(from_state: :active, to_state: :canceled)
          initial_application.save
          @new_ba = subject.call({params: {benefit_application: initial_application}}).success
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
          period = initial_application.effective_period.min..(initial_application.effective_period.min.next_month.next_month.next_month.prev_day)
          initial_application.update_attributes!(termination_reason: 'Testing, future termination', terminated_on: (TimeKeeper.date_of_record - 1.month).end_of_month, effective_period: period)
          @new_ba = subject.call({params: {benefit_application: initial_application}}).success
        end

        it 'should return a success with a BenefitApplication' do
          expect(@new_ba).to be_a(BenefitSponsors::BenefitApplications::BenefitApplication)
        end

        it 'should return a BenefitApplication with aasm_state active' do
          expect(@new_ba.aasm_state).to eq(:active)
        end

        it 'should return a BenefitApplication with remaining effective_period' do
          expect(@new_ba.effective_period).to eq((initial_application.effective_period.max.next_day)..end_of_the_year)
        end

        it 'should populate reinstated_id' do
          expect(@new_ba.reinstated_id).to eq(initial_application.id)
        end

        it 'should create new benefit_sponsor_catalog' do
          expect(@new_ba.benefit_sponsor_catalog_id).not_to eq(initial_application.benefit_sponsor_catalog_id)
        end

        context 'workflow_state_transitions' do
          it 'should record transition to_state' do
            expect(@new_ba.workflow_state_transitions.first.to_state).to eq('reinstated')
          end

          it 'should record transition to_state' do
            expect(@new_ba.workflow_state_transitions.second.to_state).to eq('active')
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
          period = initial_application.effective_period.min..(initial_application.effective_period.min.next_month.next_month.next_month.prev_day)
          initial_application.update_attributes!(termination_reason: 'Testing', terminated_on: (TimeKeeper.date_of_record - 1.month).end_of_month, effective_period: period)
          @result = subject.call({params: {benefit_application: initial_application}})
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
          period = initial_application.effective_period.min..(initial_application.effective_period.min.next_month.next_month.next_month.prev_day)
          initial_application.update_attributes!(termination_reason: 'Testing', terminated_on: (TimeKeeper.date_of_record - 1.month).end_of_month, effective_period: period)
          @result = subject.call({params: {benefit_application: initial_application}})
        end

        it 'should return failure with a message' do
          expect(@result.failure).to eq('Overlapping BenefitApplication exists for this Employer.')
        end
      end
    end

    context "benefit_application's effective starting" do
      before do
        min = TimeKeeper.date_of_record.prev_year.beginning_of_month
        initial_application.update_attributes!(aasm_state: :terminated, effective_period: min..(min.next_year.prev_day))
        initial_application.benefit_sponsor_catalog.update_attributes!(effective_period: min..(min.next_year.prev_day))
        @result = subject.call({params: {benefit_application: initial_application}})
      end

      it 'should return a failure with message' do
        expect(@result.failure).to eq("System date is not within the given BenefitApplication's effective period timeframe.")
      end
    end
  end

  context 'failure' do
    context 'no params' do
      before do
        @result = subject.call({params: {}})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing Key.')
      end
    end

    context 'invalid params' do
      before do
        @result = subject.call({params: {benefit_application: 'benefit_application'}})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Not a valid Benefit Application object.')
      end
    end

    context "invalid benefit_application's aasm state" do
      before do
        @result = subject.call({params: {benefit_application: initial_application}})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Given BenefitApplication is not in any of the [:terminated, :termination_pending, :canceled, :retroactive_canceled] states.')
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

def setup_contribution_models(benefit_sponsor_catalog)
  benefit_sponsor_catalog.product_packages.each do |pp|
    if pp.assigned_contribution_model.nil?
      pp.assigned_contribution_model = pp.contribution_model
      pp.save!
    end
    if pp.contribution_models.blank?
      pp.contribution_models = [pp.contribution_model]
      pp.save!
    end
  end
end

def load_cache
  ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  ::BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache!
end
