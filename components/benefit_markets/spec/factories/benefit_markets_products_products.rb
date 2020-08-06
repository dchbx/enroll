# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_products_product, class: 'BenefitMarkets::Products::Product' do

    benefit_market_kind  { :aca_shop }
    application_period    do
      Date.new(TimeKeeper.date_of_record.year, 1, 1)..
                          Date.new(TimeKeeper.date_of_record.year, 12, 31)
    end
    network_information  { 'DC Metro' }

    hbx_id do
      deductable = Forgery('basic').text(
        :allow_lower => false,
        :allow_upper => false,
        :allow_numeric => true,
        :allow_special => false,
        :exactly => 6
      )
    end

    title do
      deductable = Forgery('basic').text(
        :allow_lower => false,
        :allow_upper => false,
        :allow_numeric => true,
        :allow_special => false,
        :exactly => 3
      )
      "SafeCo Health $#{deductable} Deductable Premier"
    end

    description          { "Highest rated and highest value" }
    association :service_area, factory: :benefit_markets_locations_service_area

    after(:build) do |product, _evaluator|
      product.premium_tables << build_list(:benefit_markets_products_premium_table, 1)
    end

  end
end
