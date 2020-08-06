# frozen_string_literal: true

require 'rails_helper'
require 'rspec-benchmark'

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end

include ApplicationHelper

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::ContributionsController, type: :controller, dbclean: :around_each do
    render_views
    routes { SponsoredBenefits::Engine.routes }
    let(:valid_session) { {} }
    let(:current_person) { double(:current_person) }
    let(:active_user) { double(:has_hbx_staff_role? => false) }
    let(:broker_role) { double(:broker_role, id: 3) }
    let!(:rating_area) { FactoryBot.create(:rating_area, zip_code: ofice_location.address.zip, county_name: ofice_location.address.county)}

    let(:plan_design_organization) do
      FactoryBot.create :sponsored_benefits_plan_design_organization,
                        owner_profile_id: owner_profile.id,
                        sponsor_profile_id: sponsor_profile.id
    end

    let(:plan_design_proposal) do
      FactoryBot.create(:plan_design_proposal,
                        :with_profile,
                        plan_design_organization: plan_design_organization).tap do |proposal|
        sponsorship = proposal.profile.benefit_sponsorships.first
        sponsorship.initial_enrollment_period = benefit_sponsorship_enrollment_period
        sponsorship.save
      end
    end

    let(:ofice_location) { proposal_profile.office_locations.where(is_primary: true).first }

    let(:proposal_profile) { plan_design_proposal.profile }

    let(:benefit_sponsorship_enrollment_period) do
      begin_on = SponsoredBenefits::BenefitApplications::BenefitApplication.calculate_start_on_dates[0]
      end_on = begin_on + 1.year - 1.day
      begin_on..end_on
    end

    let(:benefit_sponsorship) { proposal_profile.benefit_sponsorships.first }

    let(:benefit_application) do
      FactoryBot.create :plan_design_benefit_application,
                        :with_benefit_group,
                        benefit_sponsorship: benefit_sponsorship
    end

    let(:benefit_group) do
      benefit_application.benefit_groups.first.tap do |benefit_group|
        reference_plan_id = FactoryBot.create(:plan, :with_complex_premium_tables, :with_rating_factors).id
        benefit_group.update_attributes(reference_plan_id: reference_plan_id, plan_option_kind: 'single_carrier')
      end
    end

    let(:owner_profile) { broker_agency_profile }
    let(:broker_agency) { owner_profile.organization }
    let(:general_agency_profile) { ga_profile }

    let(:employer_profile) { sponsor_profile }
    let(:benefit_sponsor) { sponsor_profile.organization }

    let!(:plan_design_census_employee) do
      FactoryBot.create_list :plan_design_census_employee, 75,
                             :with_random_age,
                             benefit_sponsorship_id: benefit_sponsorship.id
    end

    [2016, 2017, 2018, 2019].each do |year|
      let!("health_plans_for_#{year}".to_sym) do
        FactoryBot.create_list :plan,
                               77,
                               :with_complex_premium_tables,
                               active_year: year,
                               coverage_kind: "health"
      end
    end

    let(:organization) { plan_design_organization.sponsor_profile.organization }

    let!(:current_effective_date) do
      (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year
    end

    let!(:broker_agency_profile) do
      if Settings.aca.state_abbreviation == "DC" # toDo
        FactoryBot.create(:broker_agency_profile)
      else
        FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                          :with_site,
                          :with_broker_agency_profile).profiles.first
       end
    end

    let!(:sponsor_profile) do
      if Settings.aca.state_abbreviation == "DC" # toDo
        FactoryBot.create(:employer_profile)
      else
        FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                          :with_site,
                          :with_aca_shop_cca_employer_profile).profiles.first
       end
    end

    let!(:relationship_benefit) { benefit_group.relationship_benefits.first }

    before do
      allow(subject).to receive(:current_person).and_return(current_person)
      allow(subject).to receive(:active_user).and_return(active_user)
      allow(current_person).to receive(:broker_role).and_return(broker_role)
      allow(broker_role).to receive(:broker_agency_profile_id).and_return(broker_agency_profile.id)
      allow(broker_role).to receive(:benefit_sponsors_broker_agency_profile_id).and_return(broker_agency_profile.id)
    end

    it 'finished in under 10 seconds' do
      Caches::PlanDetails.load_record_cache! if Caches::PlanDetails.respond_to? :load_record_cache!
      expect do
        get :index, params: {
          plan_design_proposal_id: plan_design_proposal.id,
          benefit_group: {
            reference_plan_id: benefit_group.reference_plan_id.to_s,
            plan_option_kind: benefit_group.plan_option_kind,
            relationship_benefits_attributes: [{
              relationship: relationship_benefit.relationship,
              premium_pct: relationship_benefit.premium_pct,
              offered: relationship_benefit.offered
            }]
          },
          format: :js
        }
      end.to perform_under(10).sec
    end
  end
end
