# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_products_premium_tuple, class: 'BenefitMarkets::Products::PremiumTuple' do

    age    { 20 }
    cost  { 200 }

  end
end
