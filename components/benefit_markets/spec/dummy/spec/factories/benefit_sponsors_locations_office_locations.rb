FactoryGirl.define do
  factory :benefit_sponsors_locations_office_location, class: 'BenefitSponsors::Locations::OfficeLocation' do
    is_primary  false
    address { FactoryGirl.build(:benefit_sponsors_locations_address, kind: "branch") }

    trait :primary do
      is_primary true
      address { FactoryGirl.build(:benefit_sponsors_locations_address, kind: "primary") }
    end

    trait :with_massachusetts_address do
      is_primary true
      address { FactoryGirl.build(:benefit_sponsors_locations_address, :cca_shop_baseline) }
    end
  end
end
