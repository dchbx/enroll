FactoryGirl.define do
  factory :benefit_sponsors_benefit_group_assignment, class: "BenefitGroupAssignment" do
    association :benefit_group, factory: :benefit_sponsors_benefit_packages_benefit_package, strategy: :build
    start_on { benefit_group.plan_year.start_on }
    is_active true

    trait :coverage_selected do
      hbx_enrollment
      aasm_state "coverage_selected"
    end
  end
end
