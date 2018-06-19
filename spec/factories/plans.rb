FactoryGirl.define do
  factory :plan do
    sequence(:hbx_id)    { |n| n + 12345 }
    sequence(:name)      { |n| "BlueChoice Silver#{n} 2,000" }
    abbrev              "BC Silver $2k"
    sequence(:hios_id, (10..99).cycle)  { |n| "41842DC04000#{n}-01" }
    active_year         { TimeKeeper.date_of_record.year }
    coverage_kind       "health"
    metal_level         "silver"
    plan_type           "pos"
    market              "shop"
    ehb                 0.9943
    carrier_profile     { FactoryGirl.create(:carrier_profile)  } #{ BSON::ObjectId.from_time(DateTime.now) }
    minimum_age         19
    maximum_age         66
    deductible          "$500"
    family_deductible   "$500 per person | $1000 per group"

    # association :premium_tables, strategy: :build
    #
    trait :with_rating_factors do
      after :create do |plan, evaluator|
        active_year = plan.active_year
        carrier_id = plan.carrier_profile_id
        [active_year + 1, active_year, active_year - 1].each do |year|
          SicCodeRatingFactorSet.create!({
            :carrier_profile_id => carrier_id,
            :active_year => year,
            :default_factor_value => 1.0
          })
          EmployerGroupSizeRatingFactorSet.create!({
            :carrier_profile_id => carrier_id,
            :active_year => year,
            :default_factor_value => 1.0,
            :max_integer_factor_key => 1
          })
          EmployerParticipationRateRatingFactorSet.create!({
            :carrier_profile_id => carrier_id,
            :active_year => year,
            :default_factor_value => 1.0
          })
          crtf = CompositeRatingTierFactorSet.new({
            :carrier_profile_id => carrier_id,
            :active_year => year,
            :default_factor_value => 1.0
            })
          CompositeRatingTier::NAMES.each do |name|
            crtf.rating_factor_entries << RatingFactorEntry.new(factor_key: name, factor_value: 1.0)
          end
          crtf.save!
        end
      end
    end

    trait :with_dental_coverage do
      coverage_kind "dental"
       metal_level "dental"
      dental_level "high"
    end

    trait :with_premium_tables do
      transient do
        premium_tables_count 48
      end

      after(:create) do |plan, evaluator|
        start_on = Date.new(plan.active_year,1,1)
        end_on = start_on + 1.year - 1.day

        unless Settings.aca.rating_areas.empty?
          plan.service_area_id = CarrierServiceArea.for_issuer(plan.carrier_profile.issuer_hios_ids).first.service_area_id
          plan.save!
          rating_area = RatingArea.first.try(:rating_area) || FactoryGirl.create(:rating_area, rating_area: Settings.aca.rating_areas.first).rating_area
          create_list(:premium_table, evaluator.premium_tables_count, plan: plan, start_on: start_on, end_on: end_on, rating_area: rating_area)
        else
          create_list(:premium_table, evaluator.premium_tables_count, plan: plan, start_on: start_on, end_on: end_on)
        end
      end
    end

    trait :csr_00 do
      coverage_kind   "health"
      metal_level     "silver"
      market          "individual"
      csr_variant_id  "00"
    end

    trait :csr_87 do
      coverage_kind   "health"
      metal_level     "silver"
      market          "individual"
      csr_variant_id  "87"
    end

    trait :catastrophic do
      coverage_kind   "health"
      metal_level     "catastrophic"
      market          "individual"
    end

    trait :individual_health do
      coverage_kind   "health"
      market          "individual"
    end

    trait :individual_dental do
      coverage_kind   "dental"
      market          "individual"
      metal_level     "low"
    end

    trait :shop_health do
      coverage_kind   "health"
      market          "shop"
    end

    trait :shop_dental do
      coverage_kind   "dental"
      market          "shop"
      metal_level     "high"
    end

    trait :this_year do
      active_year Time.now.year
    end

    trait :next_year do
      active_year Time.now.year
    end

    trait :premiums_for_2015 do
      transient do
        premium_tables_count 48
      end

      after :create do |plan, evaluator|
        create_list(:premium_table, evaluator.premium_tables_count, plan: plan, start_on: Date.new(2015,1,1))
      end
    end


    trait :with_next_year_premium_tables do
      transient do
        next_year_premium_tables_count 48
      end
      active_year {TimeKeeper.date_of_record.next_year.year}
      after(:create) do |plan, evaluator|
        create_list(:next_year_premium_table, evaluator.next_year_premium_tables_count, plan: plan)
      end
    end

    factory :active_individual_health_plan,       traits: [:individual_health, :this_year, :with_premium_tables]
    factory :active_shop_health_plan,             traits: [:shop_health, :this_year, :with_premium_tables]
    factory :active_individual_dental_plan,       traits: [:individual_dental, :this_year, :with_premium_tables]
    factory :active_individual_catastophic_plan,  traits: [:catastrophic, :this_year, :with_premium_tables]

    factory :active_csr_87_plan,                  traits: [:csr_87, :this_year, :with_premium_tables]
    factory :active_csr_00_plan,                  traits: [:csr_00, :this_year, :with_premium_tables]

    factory :renewal_individual_health_plan,      traits: [:individual_health, :next_year, :with_premium_tables]
    factory :renewal_shop_health_plan,            traits: [:shop_health, :next_year, :with_premium_tables]

    factory :renewal_individual_dental_plan,      traits: [:individual_dental, :next_year, :with_premium_tables]
    factory :renewal_individual_catastophic_plan, traits: [:catastrophic, :next_year, :with_premium_tables]
    factory :renewal_csr_87_plan,                 traits: [:csr_87, :next_year, :with_premium_tables]
    factory :renewal_csr_00_plan,                 traits: [:csr_00, :next_year, :with_premium_tables]
  end

  factory :premium_table do
    sequence(:age, (19..66).cycle)
    start_on  TimeKeeper.date_of_record.beginning_of_year
    end_on  TimeKeeper.date_of_record.beginning_of_year.next_year - 1.day
    cost {(age * 1001.00) / 100.00}

    after :create do |pt|
      metal_hash = {
        bronze: 110.00,
        silver: 100.00,
        gold: 90.00,
        platinum: 80.00,
        dental: 10.00,
      }
      pt.update_attribute(:cost, (pt.age * 1001.00) / metal_hash[:"#{pt.plan.metal_level}"] )
    end
  end

  factory(:next_year_premium_table, {class: PremiumTable}) do
    sequence(:age, (19..66).cycle)
    start_on  {TimeKeeper.date_of_record.beginning_of_year.next_year}
    end_on    {TimeKeeper.date_of_record.beginning_of_year.next_year + 1.year - 1.day}
    cost {(age * 1001.00) / 100.00}

    after :create do |pt|
      metal_hash = {
        bronze: 110.00,
        silver: 100.00,
        gold: 90.00,
        platinum: 80.00,
        dental: 10.00,
      }
      pt.update_attribute(:cost, (pt.age * 1500.50) / (metal_hash[:"#{pt.plan.metal_level}"] || 110.0)  )
    end
  end
end

FactoryGirl.define do
  factory(:plan_template, {class: Plan}) do
    name "Some plan name"
    carrier_profile_id { BSON::ObjectId.new }
    sequence(:hios_id, (100000..999999).cycle)  { |n| "#{n}-01" }
    active_year Date.today.year
    metal_level { ["bronze","silver","gold","platinum"].shuffle.sample }

    trait :shop_health do
      market "shop"
      coverage_kind "health"
    end
    trait :ivl_health do
      market "individual"
      coverage_kind "health"
    end
    trait :shop_dental do
      market "shop"
      coverage_kind "dental"
      metal_level "dental"
      dental_level "high"
    end

    trait :ivl_dental do
      market "individual"
      coverage_kind "dental"
      metal_level "dental"
      dental_level "high"
    end
    trait :unoffered do
      sequence(:hios_id, (100000..999999).cycle)  { |n| "#{n}-00" }
    end
  end
end
