# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_products_premium_table, class: 'BenefitMarkets::Products::PremiumTable' do

    effective_period    { Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31) }
    association :rating_area, factory: :benefit_markets_locations_rating_area, strategy: :create

    after(:build) do |premium_table, _evaluator|
      (0..65).each do |age| # build tuple for default product premium ages
        premium_table.premium_tuples << build_list(:benefit_markets_products_premium_tuple, 1, age: age, cost: 200)
      end
    end
  end
end
