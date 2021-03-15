FactoryBot.define do
  factory :benefit_package do
    transient do
      coverage_year { TimeKeeper.date_of_record.year }
    end

    title {"individual_health_benefits_#{coverage_year}"}
    elected_premium_credit_strategy { "unassisted" }
    benefit_begin_after_event_offsets { [30, 60, 90] }
    benefit_effective_dates { ["first_of_month"] }
    benefit_categories { ["health"]}

    after :build do |bp, evaluator|
      issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, :kaiser_profile)
      ivl_bronze = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                     title: 'IVL Test Plan Bronze',
                                     benefit_market_kind: :aca_individual,
                                     kind: 'health', deductible: 3000,
                                     metal_level_kind: "bronze",
                                     csr_variant_id: "01",
                                     application_period: (Date.new(evaluator.coverage_year, 1, 1)..Date.new(evaluator.coverage_year, 12, 31)),
                                     issuer_profile: issuer_profile)
      ivl_silver = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                     title: 'IVL Test Plan Silver',
                                     benefit_market_kind: :aca_individual,
                                     kind: 'health',
                                     deductible: 2000,
                                     metal_level_kind: "silver",
                                     csr_variant_id: "01",
                                     application_period: (Date.new(evaluator.coverage_year, 1, 1)..Date.new(evaluator.coverage_year, 12, 31)),
                                     issuer_profile: issuer_profile)
      ivl_gold = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                   title: 'IVL Test Plan Gold',
                                   benefit_market_kind: :aca_individual,
                                   kind: 'health', deductible: 1000,
                                   metal_level_kind: "gold",
                                   csr_variant_id: "01",
                                   application_period: (Date.new(evaluator.coverage_year, 1, 1)..Date.new(evaluator.coverage_year, 12, 31)),
                                   issuer_profile: issuer_profile)
      ivl_plat = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                   title: 'IVL Test Plan Plat',
                                   benefit_market_kind: :aca_individual,
                                   kind: 'health',
                                   deductible: 500,
                                   metal_level_kind: "platinum",
                                   csr_variant_id: "01",
                                   application_period: (Date.new(evaluator.coverage_year, 1, 1)..Date.new(evaluator.coverage_year, 12, 31)),
                                   issuer_profile: issuer_profile)
      future_ivl_bronze = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                            title: 'IVL Test Plan Bronze',
                                            benefit_market_kind: :aca_individual,
                                            kind: 'health',
                                            deductible: 3000,
                                            metal_level_kind: "bronze",
                                            csr_variant_id: "01",
                                            application_period: (Date.new(evaluator.coverage_year + 1, 1, 1)..Date.new(evaluator.coverage_year + 1, 12, 31)),
                                            issuer_profile: issuer_profile)
      future_ivl_silver = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                            title: 'IVL Test Plan Silver',
                                            benefit_market_kind: :aca_individual,
                                            kind: 'health', deductible: 2000,
                                            metal_level_kind: "silver",
                                            csr_variant_id: "01",
                                            application_period: (Date.new(evaluator.coverage_year + 1, 1, 1)..Date.new(evaluator.coverage_year + 1, 12, 31)),
                                            issuer_profile: issuer_profile)
      future_ivl_gold = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                          title: 'IVL Test Plan Gold',
                                          benefit_market_kind: :aca_individual,
                                          kind: 'health',
                                          deductible: 1000,
                                          metal_level_kind: "gold",
                                          csr_variant_id: "01",
                                          application_period: (Date.new(evaluator.coverage_year + 1, 1, 1)..Date.new(evaluator.coverage_year + 1, 12, 31)),
                                          issuer_profile: issuer_profile)
      future_ivl_plat = FactoryBot.create(:benefit_markets_products_health_products_health_product,
                                          title: 'IVL Test Plan Plat',
                                          benefit_market_kind: :aca_individual,
                                          kind: 'health',
                                          deductible: 500,
                                          metal_level_kind: "platinum",
                                          csr_variant_id: "01",
                                          application_period: (Date.new(evaluator.coverage_year + 1, 1, 1)..Date.new(evaluator.coverage_year + 1, 12, 31)),
                                          issuer_profile: issuer_profile)
      bp.benefit_ids = [ivl_bronze.id, ivl_silver.id, ivl_gold.id, ivl_plat.id, future_ivl_bronze.id, future_ivl_silver.id, future_ivl_gold.id, future_ivl_plat.id ]
    end

    trait :next_coverage_year_title do
      title {"individual_health_benefits_#{coverage_year + 1}"}
    end

    trait :last_coverage_year_title do
      title {"individual_health_benefits_#{coverage_year - 1}"}
    end
  end
end
