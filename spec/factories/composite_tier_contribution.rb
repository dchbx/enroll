FactoryGirl.define do
  factory :composite_tier_contribution do
    composite_rating_tier           { 'employee_only' }
    employer_contribution_percent   { 50 }
    offered                         { true }
  end
end
