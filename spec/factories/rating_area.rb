FactoryGirl.define do
  factory :rating_area do
    zip_code '10010'
    county_name 'Hampstead'
    rating_area Settings.aca.rating_areas.first
    zip_code_in_multiple_counties false
  end

  trait :multiple_counties do
    zip_code_in_multiple_counties true
  end

end
