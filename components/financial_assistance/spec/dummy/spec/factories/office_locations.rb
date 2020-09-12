# frozen_string_literal: true

FactoryBot.define do
  factory :office_location do

    is_primary  { false }
    address { FactoryBot.build(:address, kind: "branch") }
    phone   { FactoryBot.build(:phone, kind: "work") }

    trait :with_mailing_address do
      address { FactoryBot.build(:address, kind: "mailing") }
    end

    trait :primary do
      is_primary { true }
      address { FactoryBot.build(:address, kind: "primary") }
    end

  end
end
