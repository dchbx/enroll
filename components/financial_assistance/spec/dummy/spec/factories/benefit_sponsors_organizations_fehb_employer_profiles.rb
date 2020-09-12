# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_organizations_fehb_employer_profile, class: 'BenefitSponsors::Organizations::FehbEmployerProfile' do
    organization { FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_site) }

    is_benefit_sponsorship_eligible { true }

    transient do
      site { nil }
      office_locations_count { 1 }
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :with_massachusetts_address)
    end

    trait :with_benefit_sponsorship do
      after :build do |profile, _evaluator|
        profile.add_benefit_sponsorship
      end
    end
  end
end
