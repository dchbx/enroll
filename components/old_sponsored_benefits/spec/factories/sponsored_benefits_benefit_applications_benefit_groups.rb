FactoryGirl.define do
  factory :sponsored_benefits_benefit_applications_benefit_group, class: 'SponsoredBenefits::BenefitApplications::BenefitGroup' do
    effective_on_kind "date_of_hire"
    terminate_on_kind "end_of_month"
    plan_option_kind "single_plan"
    description "my first benefit group"
    effective_on_offset 0
  end
end
