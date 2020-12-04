FactoryBot.define do
  factory :benefit_group_assignment, class: 'BenefitGroupAssignment' do
    benefit_group { build(:benefit_sponsors_benefit_packages_benefit_package) }
    start_on { benefit_group.effective_period.min }
  end
end
