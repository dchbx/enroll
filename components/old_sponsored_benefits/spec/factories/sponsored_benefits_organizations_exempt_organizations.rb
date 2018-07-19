FactoryGirl.define do
  factory :sponsored_benefits_organizations_exempt_organization, class: 'SponsoredBenefits::Organizations::ExemptOrganization' do
    legal_name "ACME Widgets, Inc."
    dba "ACME Widgets Co."
    entity_kind :s_corporation

    office_locations do
      [ build(:sponsored_benefits_office_location, :primary) ]
    end

    # association :profiles, factory: :sponsored_benefits_organizations_hbx_profile
    profiles { [ build(:sponsored_benefits_organizations_aca_shop_dc_employer_profile) ] }

    trait :with_site do
      before :build do |organization, evaluator|
        build(:sponsored_benefits_site, owner_organization: organization, site_organizations: [organization])
      end
    end

    trait :with_hbx_profile do
      after :build do |organization, evaluator|
        build(:sponsored_benefits_organizations_hbx_profile)
      end
    end
    
    trait :with_hbx_profile do
      after :build do |organization, evaluator|
        organization.profiles << build(:sponsored_benefits_organizations_hbx_profile)
      end
    end

  end


# factory :sponsored_benefits_organizations_exempt_organization_with_profiles, parent: :sponsored_benefits_organizations_exempt_organization do |profile|
#   profiles { build_profile :sponsored_benefits_organizations_hbx_profile, 1 }
# end


end
