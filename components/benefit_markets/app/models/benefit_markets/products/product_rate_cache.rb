module BenefitMarkets
  module Products
    # Provides a cached, efficient lookup for referencing rate values
    # by multiple keys.
    class ProductRateCache
      def self.initialize_rate_cache!
        $product_rate_age_bounding_cache = Hash.new 
        $product_rate_calculation_cache = Hash.new do |h, k|
          h[k] = (Hash.new do |h2, k2|
            h2[k2] = (Hash.new do |h3, k3|
              h3[k3] = Array.new
            end)
          end)
        end
        rating_area_cache = {}
        BenefitMarkets::Locations::RatingArea.each do |ra|
          rating_area_cache[ra.id] = ra.exchange_provided_code
        end
        BenefitMarkets::Products::Product.each do |product|
          $product_rate_age_bounding_cache[product.id] = {
            minimum: product.premium_ages.min, 
            maximum: product.premium_ages.max
          }
          product.premium_tables.each do |pt|
            r_area_tag = rating_area_cache[pt.rating_area_id]
            pt.premium_tuples.each do |tuple|
              $product_rate_calculation_cache[product.id][r_area_tag][tuple.age] = (
                $product_rate_calculation_cache[product.id][r_area_tag][tuple.age] + 
                [{
                  start_on: pt.effective_period.min,
                  end_on: pt.effective_period.max,
                  cost: tuple.cost
                }]
              )
            end
          end
        end
      end

      def self.age_bounding(plan_id, coverage_age)
        plan_age = $product_rate_age_bounding_cache[plan_id]
        return plan_age[:minimum] if coverage_age < plan_age[:minimum]
        return plan_age[:maximum] if coverage_age > plan_age[:maximum]
        coverage_age
      end

      # Return the base rate value from the product cache.
      # @param product [Product] the product for which I desire the value
      # @param rate_schedule_date [Date] the date on which the rate schedule
      #   should be active
      # @param coverage_age [Integer] the age of the covered party on the
      #   applicable date
      # @param rating_area [String] the rating area in which the rates apply
      # @return [Float, BigDecimal] the basis rate
      def self.lookup_rate(
        product,
        rate_schedule_date,
        coverage_age,
        rating_area
      )
        calc_age = age_bounding(product.id, coverage_age)
        age_record = $product_rate_calculation_cache[product.id][rating_area][calc_age].detect do |pt|
          (pt[:start_on] <= rate_schedule_date) && (pt[:end_on] >= rate_schedule_date)
        end
        age_record[:cost]
      end
    end
  end
end
