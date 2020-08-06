# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_organizations_profile, class: 'BenefitSponsors::Organizations::Profile' do

    contact_method { :paper_and_electronic }

    transient do
      office_locations_count { 1 }
      office_location_kind { :primary }
    end

    after(:build) do |_office_locations_count, evaluator|
      create_list(:office_location, evaluator.office_locations_count, evaluator.office_location_kind, office_location: office_location)
    end

  end
end
