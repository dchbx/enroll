FactoryGirl.define do
  factory :general_agency_role do
    person { FactoryGirl.create(:person) }
    sequence(:npn) {|n| "2002345#{n}" }
    provider_kind {"broker"}
  end
end
