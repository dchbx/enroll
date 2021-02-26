FactoryBot.define do
  factory :benefit_group_assignment do
    benefit_group
    start_on { benefit_group.plan_year.start_on }

    trait :coverage_selected do
      hbx_enrollment
    end
  end
end
