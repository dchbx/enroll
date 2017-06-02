FactoryGirl.define do
  factory :carrier_profile do
    organization  { FactoryGirl.create(:organization, legal_name: "UnitedHealthcare", dba: "United") }
    abbrev        "UHIC"
  end
end
