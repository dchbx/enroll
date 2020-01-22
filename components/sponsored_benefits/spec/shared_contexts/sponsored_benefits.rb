RSpec.shared_context "set up broker agency profile for BQT, by using configuration settings", :shared_context => :metadata do

  let(:plan_design_organization) { FactoryBot.create(:sponsored_benefits_plan_design_organization,
    owner_profile_id: owner_profile.id,
    sponsor_profile_id: sponsor_profile.id
  )}

  let(:prospect_plan_design_organization) { FactoryBot.create(:sponsored_benefits_plan_design_organization,
    owner_profile_id: owner_profile.id,
    sponsor_profile_id: nil
  )}

  let(:plan_design_organization_with_assigned_ga) {
    plan_design_organization.general_agency_accounts.create(
      start_on: TimeKeeper.date_of_record,
      broker_role_id: owner_profile.primary_broker_role.id
    ).tap do |account|
      account.general_agency_profile = general_agency_profile
      account.broker_agency_profile = owner_profile
      account.save
    end
    plan_design_organization
  }

  let(:plan_design_proposal) {
    FactoryBot.create(:plan_design_proposal,
      :with_profile,
      plan_design_organization: plan_design_organization
    ).tap do |proposal|
      sponsorship = proposal.profile.benefit_sponsorships.first
      sponsorship.initial_enrollment_period = benefit_sponsorship_enrollment_period
      sponsorship.save
    end
  }

  let(:prospect_plan_design_proposal) {
    FactoryBot.create(:plan_design_proposal,
      :with_profile,
      plan_design_organization: prospect_plan_design_organization
    ).tap do |proposal|
      sponsorship = proposal.profile.benefit_sponsorships.first
      sponsorship.initial_enrollment_period = benefit_sponsorship_enrollment_period
      sponsorship.save
    end
  }

  let(:proposal_profile) { plan_design_proposal.profile }
  let(:prospect_proposal_profile) {prospect_proposal_profile.profile}

  let(:current_effective_date){ TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:benefit_sponsorship_enrollment_period) { current_effective_date..current_effective_date.next_year.prev_day }

  let(:benefit_sponsorship) { proposal_profile.benefit_sponsorships.first }
  let(:prospect_benefit_sponsorship) { prospect_proposal_profile.benefit_sponsorships.first}

  let(:benefit_application) { FactoryBot.create(:plan_design_benefit_application,
    :with_benefit_group,
    effective_period: current_effective_date..current_effective_date.next_year.prev_day,
    benefit_sponsorship: benefit_sponsorship
  )}

  let(:prospect_benefit_application) { FactoryBot.create(:plan_design_benefit_application,
    :with_benefit_group,
    benefit_sponsorship: benefit_sponsorship
  )}

  let(:benefit_group) { benefit_application.benefit_groups.first }

  let(:prospect_benefit_group) { prospect_benefit_application.benefit_groups.first }

  let(:owner_profile) { broker_agency_profile }
  let(:broker_agency) { owner_profile.organization }
  let(:general_agency_profile) { ga_profile }

  let(:employer_profile) { sponsor_profile }
  let(:benefit_sponsor) { sponsor_profile.organization }

  let(:plan_design_census_employee) { FactoryBot.create(:plan_design_census_employee,
    benefit_sponsorship_id: benefit_sponsorship.id
  )}

  let(:prospect_plan_design_census_employee) { FactoryBot.create(:plan_design_census_employee,
    benefit_sponsorship_id: prospect_benefit_sponsorship.id
  )}

  let(:organization) { plan_design_organization.sponsor_profile.organization }

  let(:health_reference_plan) { health_plan }
  let(:dental_reference_plan) { dental_plan }

  let(:health_reference_product) { health_product }
  let(:dental_reference_product) { dental_product }

  def health_plan
    if Settings.aca.state_abbreviation == "DC"
      FactoryBot.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: current_effective_date.year)
    else
      FactoryBot.create(:plan, :with_premium_tables, :with_rating_factors, coverage_kind: "health", active_year: current_effective_date.year)
    end
  end

  def health_product
    FactoryBot.create(:benefit_markets_products_health_products_health_product,
      :with_renewal_product,
      application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
      product_package_kinds: [:single_issuer, :metal_level, :single_product],
      service_area: service_area,
      renewal_service_area: renewal_service_area,
      metal_level_kind: :gold
    )
  end

  def dental_plan
    if Settings.aca.state_abbreviation == "DC"
      FactoryBot.create(:plan, :with_premium_tables, coverage_kind: "dental", active_year: current_effective_date.year)
    else
      FactoryBot.create(:plan, :with_premium_tables, :with_rating_factors, coverage_kind: "dental", active_year: current_effective_date.year)
    end
  end

  def dental_product
    FactoryBot.create(:benefit_markets_products_dental_products_dental_product,
      :with_renewal_product,
      application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
      product_package_kinds: [:single_product],
      service_area: service_area,
      renewal_service_area: renewal_service_area,
      metal_level_kind: :dental
    )
  end

  def service_area
    return @service_area if defined? @service_area
    @service_area = FactoryBot.create(:benefit_markets_locations_service_area,
      county_zip_ids: [FactoryBot.create(:benefit_markets_locations_county_zip, county_name: 'Middlesex', zip: '01754', state: 'MA').id],
      active_year: current_effective_date.year
    )
  end

  def renewal_service_area
    return @renewal_service_area if defined? @renewal_service_area

    @renewal_service_area = FactoryBot.create(:benefit_markets_locations_service_area,
      county_zip_ids: service_area.county_zip_ids,
      active_year: service_area.active_year + 1
    )
  end

  def site_key
    Settings.site.key
  end

  def broker_agency_profile
    FactoryBot.create(
      :benefit_sponsors_organizations_general_organization,
      :with_site,
      :with_broker_agency_profile
    ).profiles.first
  end

  def sponsor_profile
    FactoryBot.create(
      :benefit_sponsors_organizations_general_organization,
      :with_site,
      "with_aca_shop_#{site_key}_employer_profile".to_sym
    ).profiles.first
  end

  def ga_profile
    FactoryBot.create(
      :benefit_sponsors_organizations_general_organization,
      :with_site,
      :with_general_agency_profile
    ).profiles.first
  end
end