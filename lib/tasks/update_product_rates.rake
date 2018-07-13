namespace :import do

  desc("converting plan rates to product rates.")
  task :product_rates => :environment do

    puts "*"*80 unless Rails.env.test?
    puts " starting plan to product import" unless Rails.env.test?

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
      service_area_map[[sa.issuer_profile_id,sa.active_year]] = sa.id
    end

    rating_area_id_cache = {}
    rating_area_cache = {}
    ::BenefitMarkets::Locations::RatingArea.all.each do |ra|
      rating_area_id_cache[[ra.active_year, ra.exchange_provided_code]] = ra.id
      rating_area_cache[ra.id] = ra
    end

    Plan.all.each do |plan|
      next if plan.active_year == 2017
      product = BenefitMarkets::Products::Product.where(hios_id: plan.hios_id).select{|a| a.application_period.first.year == 2018}.first

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

      product.premium_tables = premium_tables

    end

    puts "plan to product import finished" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end
end