FactoryBot.define do
  factory :benefit_sponsors_benefit_group_assignment, class: "BenefitGroupAssignment" do
    association :benefit_group, factory: :benefit_sponsors_benefit_packages_benefit_package, strategy: :build
    start_on { benefit_group.plan_year.start_on }
    trait :coverage_selected do
      hbx_enrollment { FactoryBot.create(:hbx_enrollment, :with_primary_family, :with_enrollment_members) }
    end
  end
end
