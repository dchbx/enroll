FactoryGirl.define do
  factory :benefit_package do
    title {"individual_health_benefits_#{TimeKeeper.date_of_record.year}"}
    elected_premium_credit_strategy { "unassisted" }
    benefit_begin_after_event_offsets { [30, 60, 90] }
    benefit_effective_dates { ["first_of_month"] }
    benefit_categories { ["health"]}

    after :build do |bp|
      ivl_bronze = FactoryGirl.create :plan, :with_premium_tables, name: 'IVL Test Plan Bronze', market: 'individual', coverage_kind: 'health', deductible: 3000, metal_level: "bronze", csr_variant_id: "01"
      ivl_silver = FactoryGirl.create :plan, :with_premium_tables, name: 'IVL Test Plan Silver', market: 'individual', coverage_kind: 'health', deductible: 2000, metal_level: "silver", csr_variant_id: "01"
      ivl_gold = FactoryGirl.create :plan, :with_premium_tables, name: 'IVL Test Plan Gold', market: 'individual', coverage_kind: 'health', deductible: 1000, metal_level: "gold", csr_variant_id: "01"
      ivl_plat = FactoryGirl.create :plan, :with_premium_tables, name: 'IVL Test Plan Plat', market: 'individual', coverage_kind: 'health', deductible: 500, metal_level: "platinum", csr_variant_id: "01"
      future_ivl_bronze = FactoryGirl.create :plan, :with_premium_tables, active_year: TimeKeeper.date_of_record.year + 1, name: 'IVL Test Plan Bronze', market: 'individual', coverage_kind: 'health', deductible: 3000, metal_level: "bronze", csr_variant_id: "01"
      future_ivl_silver = FactoryGirl.create :plan, :with_premium_tables, active_year: TimeKeeper.date_of_record.year + 1, name: 'IVL Test Plan Silver', market: 'individual', coverage_kind: 'health', deductible: 2000, metal_level: "silver", csr_variant_id: "01"
      future_ivl_gold = FactoryGirl.create :plan, :with_premium_tables, active_year: TimeKeeper.date_of_record.year + 1, name: 'IVL Test Plan Gold', market: 'individual', coverage_kind: 'health', deductible: 1000, metal_level: "gold", csr_variant_id: "01"
      future_ivl_plat = FactoryGirl.create :plan, :with_premium_tables, active_year: TimeKeeper.date_of_record.year + 1, name: 'IVL Test Plan Plat', market: 'individual', coverage_kind: 'health', deductible: 500, metal_level: "platinum", csr_variant_id: "01"
      bp.benefit_ids = [ivl_bronze.id, ivl_silver.id, ivl_gold.id, ivl_plat.id, future_ivl_bronze.id, future_ivl_silver.id, future_ivl_gold.id, future_ivl_plat.id ]
    end

    trait :next_coverage_year_title do
      title {"individual_health_benefits_#{TimeKeeper.date_of_record.year + 1}"}
    end
  end
end
