class MigrateMaProducts < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"
      say_with_time("Migrating plans for CCA") do 
        old_carrier_profile_map = {}
        CarrierProfile.all.each do |cpo|
          old_carrier_profile_map[cpo.id] = cpo.hbx_id
        end

        new_carrier_profile_map = {}
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |ipo|
          i_profile = ipo.issuer_profile
          new_carrier_profile_map[ipo.hbx_id] = i_profile.id
        end

        service_area_map = {}
        ::BenefitMarkets::Locations::ServiceArea.all.map do |sa|
          service_area_map[[sa.issuer_profile_id,sa.issuer_provided_code,sa.active_year]] = sa.id
        end

        rating_area_id_cache = {}
        rating_area_cache = {}
        ::BenefitMarkets::Locations::RatingArea.all.each do |ra|
          rating_area_id_cache[[ra.active_year, ra.exchange_provided_code]] = ra.id
          rating_area_cache[ra.id] = ra
        end

        say_with_time("Migrate primary plan data") do

          Plan.all.each do |plan|
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
            issuer_profile_id = new_carrier_profile_map[old_carrier_profile_map[plan.carrier_profile_id]]
            mapped_service_area_id = service_area_map[[issuer_profile_id,plan.service_area_id,plan.active_year]]
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
              issuer_assigned_id: plan.carrier_special_plan_identifier
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
                network_information: plan.network_information,
              }.merge(shared_attributes))
            else
              BenefitMarkets::Products::DentalProducts::DentalProduct.create!({
                product_package_kinds: ::BenefitMarkets::Products::DentalProducts::DentalProduct::PRODUCT_PACKAGE_KINDS
              }.merge(shared_attributes))
            end
          end
        end

        say_with_time("Migrate catastrophic and renewal reference plan data") do
          products = BenefitMarkets::Products::Product.all
          products.each do |product|
            year = product.application_period.first.year
            if year == 2017 # because we dont have any mappings from 2018 to 2019
              plan = Plan.where(active_year: year, hios_id: product.hios_id).first

              renewal_plan_hios_id = plan.renewal_plan.hios_id
              catastrophic_plan_hios_id = plan.cat_age_off_renewal_plan_id.present? ? plan.cat_age_off_renewal_plan.hios_id : nil

              renewal_product_2018 = BenefitMarkets::Products::Product.where(hios_id: renewal_plan_hios_id).sort_by{|a| a.application_period.first.year}.last

              catastrophic_product_2018 = if catastrophic_plan_hios_id.present?
                BenefitMarkets::Products::Product.where(hios_id: catastrophic_plan_hios_id).sort_by{|a| a.application_period.first.year}.last
              else
                nil
              end
              product.renewal_product = renewal_product_2018
              product.catastrophic_age_off_product = catastrophic_product_2018
              product.save
            end
          end
          # Now that all the plans moved over, cross-map the catastropic, age-off,
          # and renewal plans from the original data
        end
      end
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
    raise "Not reversable."
  end
end
