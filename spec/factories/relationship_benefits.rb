FactoryGirl.define do
  factory :relationship_benefit do
    relationship     :employee
    premium_pct             55
    employer_max_amt       100
    offered               true
  end
end
