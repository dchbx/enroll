namespace :seed do
  desc "Dump the employer organizations"
  task :convert_frozen_plan_to_product => :environment do

    service_area_map = {}
    ::BenefitMarkets::Locations::ServiceArea.all.map do |sa|
      service_area_map[[sa.issuer_profile_id,sa.active_year]] = sa.id
    end

    rating_area_id_cache = {}
    rating_area_cache = {}
    ::BenefitMarkets::Locations::RatingArea.all.each do |ra|
      rating_area_id_cache[[ra.active_year, ra.exchange_provided_code]] = ra.id
      rating_area_cache[ra.id] = ra
    end

    issuer_profile_id = ::BenefitSponsors::Organizations::Organization.issuer_profiles.where(legal_name: "Fallon Health").first.issuer_profile.id
    renewal_product = ::BenefitMarkets::Products::Product.where(hios_id: "88806MA0040052-01").select{|a| a.active_year == 2018 }.first

    Plan.where(active_year: 2017, hios_id: "88806MA0040051-01").each do |plan|
      premium_table_cache = Hash.new do |h, k|
        h[k] = Hash.new
      end
      plan.premium_tables.each do |pt|
        applicable_range = pt.start_on..pt.end_on
        rating_area_id = rating_area_id_cache[[plan.active_year, pt.rating_area]]
        premium_table_cache[[rating_area_id, applicable_range]][pt.age] = pt.cost
      end

      premium_tables = []
      premium_table_cache.each_pair do |k, v|
        rating_area_id, applicable_range = k
        premium_tuples = []
        v.each_pair do |pt_age, pt_cost|
          premium_tuples << ::BenefitMarkets::Products::PremiumTuple.new(
            age: pt_age,
            cost: pt_cost
          )
        end
        premium_tables << ::BenefitMarkets::Products::PremiumTable.new(
          effective_period: applicable_range,
          rating_area: rating_area_cache[rating_area_id],
          rating_area_id: rating_area_id,
          premium_tuples: premium_tuples
        )
      end

      product_kind = plan.coverage_kind
      # issuer_profile_id = new_carrier_profile_map[old_carrier_profile_map[plan.carrier_profile_id]]
      mapped_service_area_id = service_area_map[[issuer_profile_id,plan.active_year]]
      shared_attributes = {
        benefit_market_kind: "aca_#{plan.market}",
        hbx_id: plan.hbx_id,
        title: plan.name,
        issuer_profile_id: issuer_profile_id,
        hios_id: plan.hios_id,
        hios_base_id: plan.hios_base_id,
        csr_variant_id: plan.csr_variant_id,
        application_period: (Date.new(plan.active_year, 1, 1)..Date.new(plan.active_year, 12, 31)),
        service_area_id: mapped_service_area_id,
        provider_directory_url: plan.provider_directory_url,
        sbc_document: plan.sbc_document,
        deductible: plan.deductible,
        family_deductible: plan.family_deductible,
        is_reference_plan_eligible: true,
        premium_ages: (plan.minimum_age..plan.maximum_age),
        premium_tables: premium_tables,
        issuer_assigned_id: plan.carrier_special_plan_identifier,
        renewal_product: renewal_product
      }
      if product_kind.to_s.downcase == "health"
        product_package_kinds = []
        if plan.is_horizontal?
          product_package_kinds << :metal_level
        end
        if plan.is_vertical?
          product_package_kinds << :single_issuer
        end
        if plan.is_sole_source?
          product_package_kinds << :single_product
        end
        BenefitMarkets::Products::HealthProducts::HealthProduct.create!({
          health_plan_kind: plan.plan_type.downcase,
          metal_level_kind: plan.metal_level,
          product_package_kinds: product_package_kinds,
          ehb: plan.ehb,
          is_standard_plan: plan.is_standard_plan,
          rx_formulary_url: plan.rx_formulary_url,
          hsa_eligibility: plan.hsa_eligibility,
        }.merge(shared_attributes))
      else
        BenefitMarkets::Products::DentalProducts::DentalProduct.create!({
          product_package_kinds: ::BenefitMarkets::Products::DentalProducts::DentalProduct::PRODUCT_PACKAGE_KINDS
        }.merge(shared_attributes))
      end
    end
  end
end