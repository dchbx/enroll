module BenefitMarkets
  module Products
    # Provides a cached, efficient lookup for referencing rate values
    # by multiple keys.
    class ProductRateCache
      # rubocop:disable Style/GlobalVars
      def self.initialize_rate_cache!
        $product_rate_age_bounding_cache = Hash.new 
        $product_rate_calculation_cache = Hash.new do |h, k|
          h[k] = (Hash.new do |h2, k2|
            h2[k2] = (Hash.new do |h3, k3|
              h3[k3] = (Hash.new do |h4, k4|
                # rubocop:disable Style/EmptyLiteral
                h4[k4] = Array.new
                # rubocop:enable Style/EmptyLiteral
              end)
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
              $product_rate_calculation_cache[product.id][r_area_tag][tuple.age][tuple.tobacco_use_value] = (
                $product_rate_calculation_cache[product.id][r_area_tag][tuple.age][tuple.tobacco_use_value] +
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

      #This one is only for manual lookup if age record is not found
      def self.single_lookup_rate(product, rate_schedule_date, rating_area, coverage_age, tobacco_use)
        calc_age = age_bounding(product.id, coverage_age)
        rate_calculation = product.premium_tables.collect do |pt|
          pt.premium_tuples.collect do |tuple|
            [{
              start_on: pt.effective_period.min,
              end_on: pt.effective_period.max,
              cost: tuple.cost,
              age: tuple.age,
              tobacco_use: tuple.tobacco_use_value,
              rating_area: pt.rating_area.exchange_provided_code
            }]
          end
        end.flatten

        rate_calculation.detect do |rc|
          rc[:age] == calc_age &&
            rc[:rating_area] == rating_area &&
            rc[:start_on] <= rate_schedule_date &&
            rc[:end_on] >= rate_schedule_date &&
            rc[:tobacco_use] == tobacco_use
        end
      end

      # Return the base rate value from the product cache.
      # @param product [Product] the product for which I desire the value
      # @param rate_schedule_date [Date] the date on which the rate schedule
      #   should be active
      # @param coverage_age [Integer] the age of the covered party on the
      #   applicable date
      # @param rating_area [String] the rating area in which the rates apply
      # @param tobacco_use [String] the tobacco use, is 'NA', 'Y', or 'N'
      # @return [Float, BigDecimal] the basis rate
      def self.lookup_rate(
        product,
        rate_schedule_date,
        coverage_age,
        rating_area,
        tobacco_use = 'NA'
      )
        calc_age = age_bounding(product.id, coverage_age)
        age_record = $product_rate_calculation_cache[product.id][rating_area][calc_age][tobacco_use].detect do |pt|
          (pt[:start_on] <= rate_schedule_date) && (pt[:end_on] >= rate_schedule_date)
        end

        unless age_record.present?
          #This one is only for manual lookup if age record is not found
          age_record = single_lookup_rate(product, rate_schedule_date, rating_area, coverage_age, tobacco_use)
        end

        age_record[:cost]
      end
      # rubocop:enable Style/GlobalVars
    end
  end
end
