# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_locations_county_zip, class: 'BenefitMarkets::Locations::CountyZip' do

    county_name { "Hampden" }
    zip { "20024" }
    state { Settings.aca.state_abbreviation.to_s }

  end
end
