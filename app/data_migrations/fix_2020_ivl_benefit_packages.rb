# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
class Fix2020IvlBenefitPackages < MongoidMigrationTask

  def update_benefit_package_csr_100(bc_period_2020, ivl_products)
    ivl_health_plans_2020_for_csr_100 = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-02$/ },
                            {:metal_level_kind => 'silver', hios_id: /-02$/ }]}]
    ).select{|a| a.active_year == 2020}.entries.collect(&:_id)

    # Find 2020 benefit package with csr_100 as cost sharing
    benefit_package = bc_period_2020.benefit_packages.where(:"benefit_eligibility_element_group.cost_sharing" => 'csr_100').first
    benefit_package.update_attributes!(benefit_ids: ivl_health_plans_2020_for_csr_100)
    bc_period_2020.save!
  end

  def create_benefit_package_csr_0(bc_period_2020, ivl_products)
    ivl_health_plans_2020_for_csr_0 = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-01$/ },
                            {:metal_level_kind => 'silver', hios_id: /-01$/ }]}]
    ).select{|a| a.active_year == 2020}.entries.collect(&:_id)

    benefit_eligibility_element_group_params = { market_places: ['individual'],
                                                 enrollment_periods: ['open_enrollment', 'special_enrollment'],
                                                 family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
                                                 benefit_categories: ['health'],
                                                 incarceration_status: ['unincarcerated'],
                                                 age_range: 0..0,
                                                 cost_sharing: 'csr_0',
                                                 citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
                                                 residency_status: ['state_resident'],
                                                 ethnicity: ['any'] }

    benefit_package_params = { title: 'individual_health_benefits_csr_0_2020',
                               elected_premium_credit_strategy: 'allocated_lump_sum_credit',
                               benefit_ids: ivl_health_plans_2020_for_csr_0,
                               benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(benefit_eligibility_element_group_params) }

    individual_health_benefit_package_for_csr_0 = BenefitPackage.new(benefit_package_params)

    bc_period_2020.benefit_packages << individual_health_benefit_package_for_csr_0
    bc_period_2020.benefit_packages.each(&:save!)
    bc_period_2020.save!
  end

  def create_benefit_package_csr_limited(bc_period_2020, ivl_products)
    ivl_health_plans_2020_for_csr_limited = ivl_products.where(
      "$and" => [{ :kind => 'health'},
                 {"$or" => [{:metal_level_kind.in => %w[platinum gold bronze], hios_id: /-03$/ },
                            {:metal_level_kind => 'silver', hios_id: /-03$/ }]}]
    ).select{|a| a.active_year == 2020}.entries.collect(&:_id)

    benefit_eligibility_element_group_params = { market_places: ['individual'],
                                                 enrollment_periods: ['open_enrollment', 'special_enrollment'],
                                                 family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
                                                 benefit_categories: ['health'],
                                                 incarceration_status: ['unincarcerated'],
                                                 age_range: 0..0,
                                                 cost_sharing: 'csr_limited',
                                                 citizenship_status: ['us_citizen', 'naturalized_citizen', 'alien_lawfully_present', 'lawful_permanent_resident'],
                                                 residency_status: ['state_resident'],
                                                 ethnicity: ['any'] }

    benefit_package_params = { title: 'individual_health_benefits_csr_limited_2020',
                               elected_premium_credit_strategy: 'allocated_lump_sum_credit',
                               benefit_ids: ivl_health_plans_2020_for_csr_limited,
                               benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(benefit_eligibility_element_group_params) }

    individual_health_benefit_package_for_csr_limited = BenefitPackage.new(benefit_package_params)

    bc_period_2020.benefit_packages << individual_health_benefit_package_for_csr_limited
    bc_period_2020.benefit_packages.each(&:save!)
    bc_period_2020.save!
  end

  def migrate
    hbx = HbxProfile.current_hbx
    bc_period_2020 = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2020 }
    ivl_products = BenefitMarkets::Products::Product.aca_individual_market
    update_benefit_package_csr_100(bc_period_2020, ivl_products)
    create_benefit_package_csr_0(bc_period_2020, ivl_products)
    create_benefit_package_csr_limited(bc_period_2020, ivl_products)
    puts 'Successfully updated benefit_package with csr_100 and created benefit_package for csr_0' unless Rails.env.test?
  rescue StandardError => e
    puts "---FAILED--- to fix 2020 ivl benefit packages, error: #{e.message}" unless Rails.env.test?
  end
end
