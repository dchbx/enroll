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

    #association :employee_role, strategy: :build

    after(:create) do |p, evaluator|
      create_list(:address, 2, person: p)
      create_list(:phone, 2, person: p)
      create_list(:email, 2, person: p)
      #create_list(:employee_role, 1, person: p)
    end

    trait :with_work_email do
      emails { [FactoryGirl.build(:email, kind: "work") ] }
    end

    trait :with_work_phone do
      phones { [FactoryGirl.build(:phone, kind: "work") ] }
    end

    trait :without_first_name do
      first_name ' '
    end

    trait :without_last_name do
      last_name ' '
    end

    factory :invalid_person, traits: [:without_first_name, :without_last_name]

    trait :male do
      gender "male"
    end

    trait :female do
      gender "female"
    end

    trait :with_employee_role do
      after(:create) do |p, evaluator|
        create_list(:employee_role, 1, person: p)
      end
    end

    trait :with_employer_staff_role do
      after(:create) do |p, evaluator|
        create_list(:employer_staff_role, 1, person: p)
      end
    end

    trait :with_general_agency_staff_role do
      after(:create) do |p, evaluator|
        create_list(:general_agency_staff_role, 1, person: p)
      end
    end

    trait :with_hbx_staff_role do
      after(:create) do |p, evaluator|
        create_list(:hbx_staff_role, 1, person: p)
      end
    end

    trait :with_broker_role do
      after(:create) do |p, evaluator|
        create_list(:broker_role, 1, person: p)
      end
    end

    trait :with_consumer_role do
      after(:create) do |p, evaluator|
        create_list(:consumer_role, 1, person: p)
      end
    end

    trait :with_employee_role do
      after(:create) do |p, evaluator|
        create_list(:employee_role, 1, person: p)
      end
    end

    trait :with_assister_role do
      after(:create) do |p, evaluator|
        create_list(:assister_role, 1, person: p)
      end
    end

    trait :with_csr_role do
      after(:create) do |p, evaluator|
        create_list(:csr_role, 1, person: p)
      end
    end

    trait :with_family do
      after :create do |person|
        family = FactoryGirl.create :family, :with_primary_family_member, person: person
      end
    end

    factory :male, traits: [:male]
    factory :female, traits: [:female]

    transient do
      census_employee_id nil
      employer_profile_id nil
      hired_on nil
    end

    factory :person_with_employee_role do

      after(:create) do |person, evaluator|
        create_list(:employee_role, 1, person: person, census_employee_id: evaluator.census_employee_id, employer_profile_id: evaluator.employer_profile_id, hired_on: evaluator.hired_on)
      end
    end
  end
end
