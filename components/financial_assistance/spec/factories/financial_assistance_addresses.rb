# frozen_string_literal: true

FactoryBot.define do
  factory :financial_assistance_address, class: "::FinancialAssistance::Locations::Address" do
    kind { 'home' }
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street NE" }
    sequence(:address_2, 111) { |n| "##{n}" }
    city { 'Washington' }
    state { Settings.aca.state_abbreviation }
    zip { '01001' }
    county { 'Hampden' }
  end
end
