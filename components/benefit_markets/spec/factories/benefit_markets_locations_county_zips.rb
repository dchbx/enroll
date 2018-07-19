FactoryGirl.define do
  factory :benefit_markets_locations_county_zip, class: 'BenefitMarkets::Locations::CountyZip' do

    county_name "Hampden"
    zip "01001"
    state "#{Settings.aca.state_abbreviation}"

  end
end
