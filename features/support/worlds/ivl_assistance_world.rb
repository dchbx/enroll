# frozen_string_literal: true

module IvlAssistanceWorld
  def update_a_standard_plan_to_be_csr
    products = ::BenefitMarkets::Products::Product.health_products.where(metal_level_kind: :silver)
    products.each do |product|
      product.update_attributes!(csr_variant_id: '02', is_standard_plan: false)
    end
  end

  def reset_plans_to_be_standard
    products = ::BenefitMarkets::Products::Product.health_products.where(metal_level_kind: :silver)
    products.each do |product|
      product.update_attributes!(csr_variant_id: '01', is_standard_plan: true)
    end
  end

  def create_tax_household_and_eligibility_determination(family)
    tax_household = TaxHousehold.new(
      effective_starting_on: TimeKeeper.date_of_record,
      is_eligibility_determined: true,
      submitted_at: TimeKeeper.date_of_record
      )
    family.active_household.tax_households.destroy_all
    family.active_household.tax_households << tax_household
    family.active_household.save!
    tax_household.eligibility_determinations << EligibilityDetermination.new(
      source: 'Admin',
      max_aptc: 100.00,
      csr_percent_as_integer: 100,
      determined_at: TimeKeeper.date_of_record
      )
    tax_household.eligibility_determinations.each { |ed| ed.save!}
    tax_household.save!
    family.save!
    tax_household
  end

  def create_aptc_only_eligibilty_for_the_family
    create_slcsp_product
    family = Family.all.first
    tax_household = create_tax_household_and_eligibility_determination(family)
    tax_household.tax_household_members << TaxHouseholdMember.new(
      applicant_id: family.family_members[0].id,
      is_subscriber: true,
      is_ia_eligible: true,
      is_medicaid_chip_eligible: false
      )
    tax_household.tax_household_members << TaxHouseholdMember.new(
      applicant_id: family.family_members[1].id,
      is_subscriber: false,
      is_ia_eligible: true,
      is_medicaid_chip_eligible: false
      )
    tax_household.save!
    family.active_household.save!
    family.save!
  end

  def create_slcsp_product
    date = TimeKeeper.date_of_record
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    current_benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(date)}
    future_benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(date + 1.year)}
    current_silver_product = BenefitMarkets::Products::Product.all.aca_individual_market.by_year(date.year).by_metal_level_kind('silver').first
    future_silver_product =  BenefitMarkets::Products::Product.all.aca_individual_market.by_year((date + 1.year).year).by_metal_level_kind('silver').first
    current_benefit_coverage_period.update_attributes(slcsp_id: current_silver_product.id)
    future_benefit_coverage_period.update_attributes(slcsp_id: future_silver_product.id)
  end

  def create_mixed_eligibilty_for_the_family
    family = Family.all.first
    tax_household = create_tax_household_and_eligibility_determination(family)
    tax_household.tax_household_members << TaxHouseholdMember.new(
      applicant_id: family.family_members[0].id,
      is_subscriber: true,
      is_ia_eligible: true,
      is_medicaid_chip_eligible: false
      )
    tax_household.tax_household_members << TaxHouseholdMember.new(
      applicant_id: family.family_members[1].id,
      is_subscriber: false,
      is_ia_eligible: false,
      is_medicaid_chip_eligible: true
      )
    tax_household.save!
    family.active_household.save!
    family.save!
  end
end

World(IvlAssistanceWorld)
