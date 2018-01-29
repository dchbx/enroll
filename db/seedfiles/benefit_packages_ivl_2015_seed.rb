puts "::: Creating IVL 2015 benefit packages :::"

## 2015 Benefit Packages

hbx = HbxProfile.current_hbx

# Second lowest cost silver plan
slcsp_2015 = Plan.where(active_year: 2015).and(hios_id: "94506DC0390006-01").first
# slcsp_2015 = Plan.where(active_year: 2015).and(hios_id: "94506DC0390006-01").first

bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2015 }.first
bc_period.second_lowest_cost_silver_plan = slcsp_2015

ivl_health_plans_2015         = Plan.individual_health_by_active_year(2015).health_metal_nin_catastropic.entries.collect(&:_id)
ivl_dental_plans_2015         = Plan.individual_dental_by_active_year(2015).entries.collect(&:_id)
ivl_and_cat_health_plans_2015 = Plan.individual_health_by_active_year(2015).entries.collect(&:_id)


individual_health_benefit_package = BenefitPackage.new(
  title: "individual_health_benefits_2015",
  elected_premium_credit_strategy: "unassisted",
  benefit_ids:          ivl_health_plans_2015,
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
  title: "individual_dental_benefits_2015",
  elected_premium_credit_strategy: "unassisted",
  benefit_ids:          ivl_dental_plans_2015,
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
  title: "catastrophic_health_benefits_2015",
  elected_premium_credit_strategy: "unassisted",
  benefit_ids:          ivl_and_cat_health_plans_2015,
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
  title: "native_american_health_benefits_2015",
  elected_premium_credit_strategy: "unassisted",
  benefit_ids:          ivl_health_plans_2015,
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
  title: "native_american_dental_benefits_2015",
  elected_premium_credit_strategy: "unassisted",
  benefit_ids:          ivl_dental_plans_2015,
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

ivl_health_plans_2015_for_csr_100 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_100").entries.collect(&:_id)
ivl_health_plans_2015_for_csr_94 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_94").entries.collect(&:_id)
ivl_health_plans_2015_for_csr_87 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_87").entries.collect(&:_id)
ivl_health_plans_2015_for_csr_73 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_73").entries.collect(&:_id)

individual_health_benefit_package_for_csr_100 = BenefitPackage.new(
  title: "individual_health_benefits_csr_100_2015",
  elected_premium_credit_strategy: "allocated_lump_sum_credit",
  benefit_ids:          ivl_health_plans_2015_for_csr_100,
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
  title: "individual_health_benefits_csr_94_2015",
  elected_premium_credit_strategy: "allocated_lump_sum_credit",
  benefit_ids:          ivl_health_plans_2015_for_csr_94,
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
  title: "individual_health_benefits_csr_87_2015",
  elected_premium_credit_strategy: "allocated_lump_sum_credit",
  benefit_ids:          ivl_health_plans_2015_for_csr_87,
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
  title: "individual_health_benefits_csr_73_2015",
  elected_premium_credit_strategy: "allocated_lump_sum_credit",
  benefit_ids:          ivl_health_plans_2015_for_csr_73,
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

bc_period.benefit_packages = [
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

bc_period.save!
