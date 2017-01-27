FactoryGirl.define do
  factory :employer_profile do
    organization            { FactoryGirl.build(:organization) }
    entity_kind             "c_corporation"

    transient do
      employee_roles []
    end

    trait :with_full_inbox do
      after :create do |employer_profile, evaluator|
        inbox { FactoryGirl.create(:inbox, :with_message, recipient: employer_profile) }
      end
    end

    trait :congress do
      plan_years { [FactoryGirl.build(:plan_year, :with_benefit_group_congress)] }
    end

    before :create do |employer_profile, evaluator|
      unless evaluator.employee_roles.blank?
        employer_profile.employee_roles.push *Array.wrap(evaluator.employee_roles)
      end
    end

    factory :employer_profile_congress,   traits: [:congress]
  end

end
