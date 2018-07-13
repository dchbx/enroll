FactoryGirl.define do
  factory :sponsored_benefits_office_location, class: 'SponsoredBenefits::Organizations::OfficeLocation' do
      is_primary  false
      address { FactoryGirl.build(:sponsored_benefits_locations_address, kind: "branch") }
      phone   { FactoryGirl.build(:sponsored_benefits_phone, kind: "work") }

      trait :primary do
        is_primary true
        address { FactoryGirl.build(:sponsored_benefits_locations_address, kind: "primary") }
      end
  end
end
