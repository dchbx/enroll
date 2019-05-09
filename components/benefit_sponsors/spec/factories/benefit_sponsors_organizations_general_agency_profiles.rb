FactoryBot.define do
  factory :benefit_sponsors_organizations_general_agency_profile, class: '::BenefitSponsors::Organizations::GeneralAgencyProfile' do
    entity_kind { "s_corporation" }
    market_kind { "shop" }
    organization

    transient do
      legal_name { nil }
      office_locations_count { 1 }
      assigned_site { nil }
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end

    after(:build) do |profile, evaluator|
      if profile.organization.blank?
        if evaluator.assigned_site
          profile.organization = FactoryBot.build(:benefit_sponsors_organizations_general_organization, legal_name: evaluator.legal_name, site: evaluator.assigned_site )
        else
          profile.organization = FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_site)
        end
      end
    end

    trait :with_organization_and_site do
      after(:build) do |profile, evaluator|
        site { nil }
        if evaluator.site
          site = evaluator.site
        else
          site = BenefitSponsors::Site.by_site_key(:cca).first || create(:benefit_sponsors_site, :as_hbx_profile, :with_benefit_market, :cca)
        end
        profile.organization = build(:benefit_sponsors_organizations_general_organization, site: site) unless profile.organization
      end
    end

    trait :organization do
      after(:build) do |profile, evaluator|
          site = BenefitSponsors::Site.by_site_key(:cca).first || create(:benefit_sponsors_site, :as_hbx_profile, :with_benefit_market, :cca)
        profile.organization = build(:benefit_sponsors_organizations_general_organization, site: site) unless profile.organization
      end
    end

    trait :with_staff do
      after :create do |benefit_sponsors_organizations_general_agency_profile, evaluator|
        FactoryBot.create(:general_agency_staff_role,
          benefit_sponsors_general_agency_profile_id: benefit_sponsors_organizations_general_agency_profile.id)
      end
    end
  end
end
