# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_organizations_aca_shop_cca_employer_profile, class: 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile' do

    employer_attestation  { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    sic_code              { "001" }
    referred_by           { "Other" }
    referred_reason       { "Other Reason" }

    transient do
      site { nil }
      secondary_office_locations_count { 1 }
    end

    # before(:build) do |profile, evaluator|
    #   if profile.organization.site.benefit_markets.blank?
    #     profile.organization.site.benefit_markets << create(:benefit_markets_benefit_market, site: profile.organization.site)
    #   end
    # end

    after(:build) do |profile, _evaluator|
      profile.office_locations = [build(:benefit_sponsors_locations_office_location, :with_massachusetts_address)]
    end

    trait :with_organization_and_site do
      after(:build) do |profile, evaluator|
        site = nil
        site = evaluator.site || BenefitSponsors::Site.by_site_key(:cca).first || create(:benefit_sponsors_site, :as_hbx_profile, :with_benefit_market, :cca)
        profile.organization = build(:benefit_sponsors_organizations_general_organization, site: site)
      end
    end

    trait :with_benefit_sponsorship do
      after(:build) do |profile, _evaluator|
        profile.add_benefit_sponsorship
      end
    end

    trait :with_secondary_offices do
      after(:build) do |profile, evaluator|
        profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.secondary_office_locations_count, :with_massachusetts_address)
      end
    end
  end
end
