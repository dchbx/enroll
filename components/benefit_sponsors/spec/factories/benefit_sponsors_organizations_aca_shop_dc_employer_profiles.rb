# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_organizations_aca_shop_dc_employer_profile, class: 'BenefitSponsors::Organizations::AcaShopDcEmployerProfile' do
    organization { FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_site) }

    is_benefit_sponsorship_eligible { true }

    transient do
      site { nil }
      office_locations_count { 1 }
    end

    #before(:build) do |profile, evaluator|
    #  if profile.organization.site.benefit_markets.blank?
    #    profile.organization.site.benefit_markets << create(:benefit_markets_benefit_market, site: profile.organization.site)
    #  end
    #end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :with_massachusetts_address)
      # profile.add_benefit_sponsorship if profile.benefit_sponsorships.blank?
    end

    trait :with_benefit_sponsorship do
      after :build do |profile, _evaluator|
        profile.add_benefit_sponsorship
      end
    end

  end
end
