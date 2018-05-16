FactoryGirl.define do
  factory :benefit_sponsors_organizations_aca_shop_cca_employer_profile, class: 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile' do

    organization  { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_site) }
    entity_kind   :c_corporation
    sic_code      "001"

    transient do
      office_locations_count 1
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end
  end
end
