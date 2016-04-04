FactoryGirl.define do
  factory :census_employee do
    first_name "Eddie"
    sequence(:last_name) {|n| "Vedder#{n}" }
    dob "1964-10-23".to_date
    gender "male"
    employee_relationship "self"
    hired_on "2015-04-01".to_date
    sequence(:ssn) { |n| 222222220 + n }
    is_business_owner  false
    association :address, strategy: :build
    association :email, strategy: :build
    association :employer_profile, strategy: :build

    trait :owner do
      is_business_owner  true
    end

    trait :with_enrolled_census_employee do
      aasm_state :eligible
    end
  end

end
