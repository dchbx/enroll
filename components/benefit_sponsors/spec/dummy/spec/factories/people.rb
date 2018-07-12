FactoryGirl.define do
  factory :person do
    # name_pfx 'Mr'
    first_name 'John'
    # middle_name 'X'
    sequence(:last_name) {|n| "Smith#{n}" }
    # name_sfx 'Jr'
    dob "1972-04-04".to_date
    is_incarcerated false
    is_active true
    gender "male"

    trait :with_broker_role do
      after(:create) do |p, evaluator|
        create_list(:broker_role, 1, person: p)
      end
    end

    trait :with_work_phone do
      phones { [FactoryGirl.build(:phone, kind: "work") ] }
    end

    trait :with_work_email do
      emails { [FactoryGirl.build(:email, kind: "work") ] }
    end
  end
end
