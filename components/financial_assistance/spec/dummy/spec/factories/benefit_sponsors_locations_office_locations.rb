# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_locations_office_location, class: 'BenefitSponsors::Locations::OfficeLocation' do
    is_primary  { false }
    address { FactoryBot.build(:benefit_sponsors_locations_address, kind: "branch") }
    phone   { FactoryBot.build(:benefit_sponsors_locations_phone, kind: "work") }

    trait :primary do
      is_primary { true }
      address { FactoryBot.build(:benefit_sponsors_locations_address, kind: "primary") }
    end

    trait :with_massachusetts_address do
      is_primary { true }
      address { FactoryBot.build(:benefit_sponsors_locations_address, :cca_shop_baseline) }
      phone   do
        FactoryBot.build(:benefit_sponsors_locations_phone,
                         kind: "work",
                         area_code: 617,
                         number: 5_551_212)
      end
    end
  end
end
