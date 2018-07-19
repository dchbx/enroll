module BenefitSponsors
  module PricingCalculators
    class CcaShopListBillPricingCalculator < PricingCalculator
      class CalculatorState
        attr_reader :total
        attr_reader :member_totals

        def initialize(p_calculator, product, p_model, p_unit_map, r_coverage, c_eligibility_dates, gs_factor, sc_factor)
          @pricing_calculator = p_calculator
          @pricing_unit_map = p_unit_map
          @pricing_model = p_model
          @relationship_totals = Hash.new { |h, k| h[k] = 0 }
          @total = 0.00
          @member_totals = Hash.new
          @rate_schedule_date = r_coverage.rate_schedule_date
          @eligibility_dates = c_eligibility_dates
          @previous_product = r_coverage.previous_product
          @coverage_start_date = r_coverage.coverage_start_on
          @rating_area = r_coverage.rating_area
          @product = product
          @group_size_factor = gs_factor
          @sic_code_factor = sc_factor
        end

        def add(member)
          coverage_age = @pricing_calculator.calc_coverage_age_for(member, @product, @coverage_start_date, @eligibility_dates, @previous_product)
          relationship = member.is_primary_member? ? "self" : member.relationship
          rel = @pricing_model.map_relationship_for(relationship, coverage_age, member.is_disabled?)
          pu = @pricing_unit_map[rel.to_s]
          @relationship_totals[rel.to_s] = @relationship_totals[rel.to_s] + 1
          rel_count = @relationship_totals[rel.to_s]
          member_price = if (pu.eligible_for_threshold_discount && (rel_count > pu.discounted_above_threshold))
                           0.00
                         else
                           # Do calc
                           ::BenefitMarkets::Products::ProductRateCache.lookup_rate(
                             @product,
                             @rate_schedule_date,
                             coverage_age,
                             @rating_area
                           )
                         end
          member_value = BigDecimal.new((member_price * @group_size_factor * @sic_code_factor).to_s).round(2)
          @member_totals[member.member_id] = member_value
          @total = BigDecimal.new((@total + member_value).to_s).round(2)
          self
        end
      end

      def initialize
        @pricing_unit_map = {}
      end

      def calculate_price_for(pricing_model, benefit_roster_entry, sponsor_contribution)
        pricing_unit_map = pricing_unit_map_for(pricing_model)
        roster_entry = benefit_roster_entry
        roster_coverage = benefit_roster_entry.group_enrollment
        age_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
        product = roster_coverage.product
        coverage_eligibility_dates = {}
        roster_coverage.member_enrollments.each do |m_en|
          coverage_eligibility_dates[m_en.member_id] = m_en.coverage_eligibility_on
        end
        sorted_members = roster_entry.members.sort_by do |rm|
          coverage_age = age_calculator.calc_coverage_age_for(rm, product, roster_coverage.coverage_start_on, coverage_eligibility_dates, roster_coverage.previous_product)
          [pricing_model.map_relationship_for(rm.relationship, coverage_age, rm.is_disabled?), rm.dob]
        end
        # CCA policy decision: in non-composite group size is always treated as 1
        gs_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_group_size_factor(product, 1)
        sc_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_sic_code_factor(product, sponsor_contribution.sic_code)
        calc_state = CalculatorState.new(age_calculator, product, pricing_model, pricing_unit_map, roster_coverage, coverage_eligibility_dates, gs_factor, sc_factor)
        calc_results = sorted_members.inject(calc_state) do |calc, mem|
          calc.add(mem)
        end
        benefit_roster_entry.group_enrollment.member_enrollments.each do |m_en|
          m_en.product_price = calc_results.member_totals[m_en.member_id]
        end
        benefit_roster_entry.group_enrollment.product_cost_total = calc_results.total
        benefit_roster_entry
      end

      def pricing_unit_map_for(pricing_model)
        @pricing_unit_map[pricing_model.id] ||= pricing_model.pricing_units.inject({}) do |acc, pu|
          acc[pu.name.to_s] = pu
          acc
        end
      end
    end
  end
end
