FactoryGirl.define do
  factory :carrier_profile do
    organization  { FactoryGirl.create(:organization, legal_name: "United Health Care", dba: "United") }
    abbrev        "UHIC"
  end
end
