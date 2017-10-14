namespace :import do
  desc "Create 2018 SLCSP and  IVL Benefit package"
  task :slcsp_and_benefit_package_2018, [:file] => :environment do |task, args|
    puts "::: Creating IVL 2018 SLCSP and benefit packages :::"

    beginning_of_year = TimeKeeper.date_of_record.beginning_of_year
    end_of_year = TimeKeeper.date_of_record.end_of_year
     Plan.new({"_id"=>BSON::ObjectId('59decc998b35bce37e0151e1'),
     "ehb"=>0.9821,
     "minimum_age"=>14,
     "maximum_age"=>64,
     "is_active"=>true,
     "name"=>"KP DC Silver 6000/35/Dental",
     "hios_id"=>"94506DC0390014-01",
     "hios_base_id"=>"94506DC0390014",
     "csr_variant_id"=>"01",
     "active_year"=>2018,
     "metal_level"=>"silver",
     "market"=>"individual",
     "carrier_profile_id"=>BSON::ObjectId('53e67210eb899a460300000d'),
     "coverage_kind"=>"health",
     "dental_level"=>"",
     "is_standard_plan"=>false,
     "updated_at"=>Time.now,
     "created_at"=>Time.now,
     "plan_type"=>"hmo",
     "deductible"=>"$6,000",
     "family_deductible"=>"$6000 per person | $12000 per group",
     "nationwide"=>false,
     "dc_in_network"=>true,
     "premium_tables"=>
      [{"_id"=>BSON::ObjectId('59decf21c09d07f15100d94e'),"age"=>14,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>217.24},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d94f'),"age"=>15,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>217.24},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d950'),"age"=>16,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>217.24},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d951'),"age"=>17,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>217.24},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d952'),"age"=>18,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>217.24},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d953'),"age"=>19,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>217.24},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d954'),"age"=>20,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>217.24},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d955'),"age"=>21,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>241.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d956'),"age"=>22,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>241.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d957'),"age"=>23,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>241.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d958'),"age"=>24,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>241.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d959'),"age"=>25,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>241.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d95a'),"age"=>26,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>241.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d95b'),"age"=>27,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>241.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d95c'),"age"=>28,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>247.14},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d95d'),"age"=>29,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>252.45},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d95e'),"age"=>30,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>258.76},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d95f'),"age"=>31,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>265.4},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d960'),"age"=>32,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>271.38},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d961'),"age"=>33,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>277.7},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d962'),"age"=>34,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>284.34},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d963'),"age"=>35,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>290.98},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d964'),"age"=>36,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>297.63},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d965'),"age"=>37,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>304.27},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d966'),"age"=>38,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>307.92},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d967'),"age"=>39,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>311.58},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d968'),"age"=>40,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>323.87},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d969'),"age"=>41,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>336.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d96a'),"age"=>42,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>349.78},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d96b'),"age"=>43,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>363.4},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d96c'),"age"=>44,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>377.68},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d96d'),"age"=>45,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>392.29},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d96e'),"age"=>46,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>407.57},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d96f'),"age"=>47,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>423.52},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d970'),"age"=>48,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>440.13},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d971'),"age"=>49,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>457.4},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d972'),"age"=>50,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>475.34},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d973'),"age"=>51,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>493.94},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d974'),"age"=>52,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>513.2},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d975'),"age"=>53,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>533.14},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d976'),"age"=>54,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>554.06},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d977'),"age"=>55,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>575.65},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d978'),"age"=>56,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>598.24},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d979'),"age"=>57,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>621.49},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d97a'),"age"=>58,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>645.74},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d97b'),"age"=>59,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>670.99},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d97c'),"age"=>60,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>697.23},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d97d'),"age"=>61,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>724.47},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d97e'),"age"=>62,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>724.47},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d97f'),"age"=>63,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>724.47},
       {"_id"=>BSON::ObjectId('59decf21c09d07f15100d980'),"age"=>64,"start_on"=> beginning_of_year,"end_on"=> end_of_year,"cost"=>724.47}],
     "provider_directory_url"=>"https://dc.checkbookhealth.org/dc/ ",
     "rx_formulary_url"=>"https://healthy.kaiserpermanente.org/static/health/pdfs/formulary/mid/mid_exchange_formulary.pdf",
     }).save

    # BenefitPackages - HBX 2018
    hbx = HbxProfile.current_hbx

    # Second lowest cost silver plan
    slcsp_2018 = Plan.where(active_year: 2018).and(hios_id: "94506DC0390014-01").first

    # check if benefit package is present for 2018
    bc_period_2018 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2018 }.first

    if !bc_period_2018.present?
    # create benefit package and benefit_coverage_period for 2018
      bc_period_2017 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2017 }.first
      bc_period_2018 = bc_period_2017.dup
      bc_period_2018.title = "Individual Market Benefits 2018"
      bc_period_2018.start_on = bc_period_2017.start_on + 1.year
      bc_period_2018.end_on = bc_period_2017.end_on + 1.year

      # if we need to change these dates after running this rake task in test or prod environments,
      # we should write a separate script.
      bc_period_2018.open_enrollment_start_on = Date.new(2017,11,1)
      bc_period_2018.open_enrollment_end_on = Date.new(2017,12,15)

      bc_period_2018.slcsp = slcsp_2018.id
      bc_period_2018.slcsp_id = slcsp_2018.id
    end

    bs = hbx.benefit_sponsorship
    bs.benefit_coverage_periods << bc_period_2018
    bs.save

    # bc_period_2018 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2018 }.first
    # bc_period_2018.second_lowest_cost_silver_plan = slcsp_2018

    ivl_health_plans_2018         = Plan.individual_health_by_active_year(2018).health_metal_nin_catastropic.entries.collect(&:_id)
    ivl_dental_plans_2018         = Plan.individual_dental_by_active_year(2018).entries.collect(&:_id)
    ivl_and_cat_health_plans_2018 = Plan.individual_health_by_active_year(2018).entries.collect(&:_id)

    # shop_health_plans_2018        = Plan.shop_health_by_active_year(2018).entries.collect(&:_id)
    # shop_dental_plans_2018        = Plan.shop_dental_by_active_year(2018).entries.collect(&:_id)


    ## 2018 Benefit Packages

    individual_health_benefit_package = BenefitPackage.new(
      title: "individual_health_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_health_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places:        ["individual"],
          enrollment_periods:   ["open_enrollment", "special_enrollment"],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories:   ["health"],
          incarceration_status: ["unincarcerated"],
          age_range:            0..0,
          citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
          residency_status:     ["state_resident"],
          ethnicity:            ["any"]
        )
    )

    individual_dental_benefit_package = BenefitPackage.new(
      title: "individual_dental_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_dental_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places:        ["individual"],
          enrollment_periods:   ["open_enrollment", "special_enrollment"],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories:   ["dental"],
          incarceration_status: ["unincarcerated"],
          age_range:            0..0,
          citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
          residency_status:     ["state_resident"],
          ethnicity:            ["any"]
        )
    )

    individual_catastrophic_health_benefit_package = BenefitPackage.new(
      title: "catastrophic_health_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_and_cat_health_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..30,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    native_american_health_benefit_package = BenefitPackage.new(
      title: "native_american_health_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_health_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["indian_tribe_member"]
      )
    )

    native_american_dental_benefit_package = BenefitPackage.new(
      title: "native_american_dental_benefits_2018",
      elected_premium_credit_strategy: "unassisted",
      benefit_ids:          ivl_dental_plans_2018,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["any"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["dental"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["indian_tribe_member"]
      )
    )

    ivl_health_plans_2018_for_csr_100 = Plan.individual_health_by_active_year_and_csr_kind(2018, "csr_100").entries.collect(&:_id)
    ivl_health_plans_2018_for_csr_94 = Plan.individual_health_by_active_year_and_csr_kind(2018, "csr_94").entries.collect(&:_id)
    ivl_health_plans_2018_for_csr_87 = Plan.individual_health_by_active_year_and_csr_kind(2018, "csr_87").entries.collect(&:_id)
    ivl_health_plans_2018_for_csr_73 = Plan.individual_health_by_active_year_and_csr_kind(2018, "csr_73").entries.collect(&:_id)

    individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
      title: "individual_health_benefits_csr_100_2018",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2018_for_csr_100,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_100",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_94 = BenefitPackage.new(
      title: "individual_health_benefits_csr_94_2018",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2018_for_csr_94,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_94",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_87 = BenefitPackage.new(
      title: "individual_health_benefits_csr_87_2018",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2018_for_csr_87,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_87",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    individual_health_benefit_package_for_csr_73 = BenefitPackage.new(
      title: "individual_health_benefits_csr_73_2018",
      elected_premium_credit_strategy: "allocated_lump_sum_credit",
      benefit_ids:          ivl_health_plans_2018_for_csr_73,
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        cost_sharing:         "csr_73",
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
      )
    )

    bc_period_2018.benefit_packages = [
        individual_health_benefit_package,
        individual_dental_benefit_package,
        individual_catastrophic_health_benefit_package,
        native_american_health_benefit_package,
        native_american_dental_benefit_package,
        individual_health_benefit_package_for_csr_100,
        individual_health_benefit_package_for_csr_94,
        individual_health_benefit_package_for_csr_87,
        individual_health_benefit_package_for_csr_73
      ]

    bc_period_2018.save!
    puts "Successfully created IVL 2018 Benefit Package."
  end
end
