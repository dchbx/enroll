module IvlAssistanceWorld
  def update_a_standard_plan_to_be_csr
    BenefitMarkets::Products::Product.all.each { |plan| plan.update_attributes!(csr_variant_id: '05') }
  end

  def reset_plans_to_be_standard
    BenefitMarkets::Products::Product.all.each { |plan| plan.update_attributes!(csr_variant_id: '01') }
  end

  def create_tax_household_and_eligibility_determination(family)
    active_household = family.active_household
    active_household.tax_households.build(
        effective_starting_on: (TimeKeeper.date_of_record - 10.days),
        is_eligibility_determined: true,
        submitted_at: TimeKeeper.date_of_record
    )

    active_household.save!
    tax_household = family.active_household.tax_households.first
    tax_household.eligibility_determinations.build(
        max_aptc: 100.00,
        csr_percent_as_integer: 87,
        determined_on: (TimeKeeper.date_of_record - 10.days),
        csr_eligibility_kind: 'csr_87'
    )
    tax_household.save!
    tax_household.eligibility_determinations.first.save
    family.save!
    tax_household
  end

  def create_aptc_only_eligibilty_for_the_family
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
