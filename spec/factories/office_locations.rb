FactoryGirl.define do
  factory :office_location do

    is_primary  false
    address { FactoryGirl.build(:address, kind: "branch") }
    phone   { FactoryGirl.build(:phone, kind: "work") }

    trait :with_mailing_address do
      address { FactoryGirl.build(:address, kind: "mailing") }
    end

    trait :primary do
      is_primary true
      address { FactoryGirl.build(:address, kind: "primary") }
    end

  end
end
