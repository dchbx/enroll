module BenefitSponsors
  module PricingCalculators
    class CcaCompositeTieredPriceCalculator < PricingCalculator
      class CalculatorState
        attr_reader :total
        attr_reader :member_pricing

        def initialize(p_model, r_coverage, p_determination, c_eligibility_dates)
          @age_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
          @pricing_model = p_model
          @relationship_totals = Hash.new { |h, k| h[k] = 0 }
          @member_totals = 0
          @total = 0.00
          @product = r_coverage.product
          @pricing_units = p_model.pricing_units
          @pricing_determination = p_determination
          @member_ids = []
          @member_pricing = {}
          @product = r_coverage.product
          @previous_product = r_coverage.previous_product
          @eligibility_dates = c_eligibility_dates
          @coverage_start_date = r_coverage.coverage_start_on
          @primary_member_id = nil
        end

        def add(member)
          if member.is_primary_member?
            @primary_member_id = member.member_id
          end
          coverage_age = @age_calculator.calc_coverage_age_for(member, @product, @coverage_start_date, @eligibility_dates, @previous_product)
          relationship = member.is_primary_member? ? "self" : member.relationship
          rel = @pricing_model.map_relationship_for(relationship, coverage_age, member.is_disabled?)
          @member_ids << member.member_id
          @relationship_totals[rel.to_s] = @relationship_totals[rel.to_s] + 1
          @member_totals = @member_totals + 1
          self
        end

        def finalize_results
          pricing_unit = @pricing_units.detect do |pu|
            pu.match?(@relationship_totals)
          end
          pricing_determination_tier = @pricing_determination.pricing_determination_tiers.detect do |pdt|
            pdt.pricing_unit_id == pricing_unit.id
          end
          @total = pricing_determination_tier.price
          members_total_price = 0.00
          @member_ids.each do |m_id|
            member_price = BigDecimal.new((@total / @member_totals).to_s).floor(2)
            members_total_price = BigDecimal.new((members_total_price + member_price).to_s).round(2)
            @member_pricing[m_id] = member_price
          end
          member_discrepency = BigDecimal.new((@total - members_total_price).to_s).round(2)
          @member_pricing[@primary_member_id] = BigDecimal.new((@member_pricing[@primary_member_id] + member_discrepency).to_s).round(2) 
          self
        end
      end

      def pricing_determination_builder
        CcaCompositeTierPrecalculator
      end

      def calculate_price_for(pricing_model, benefit_roster_entry, sponsor_contribution)
        pricing_determination = sponsor_contribution.sponsored_benefit.latest_pricing_determination
        r_coverage = benefit_roster_entry.group_enrollment
        coverage_eligibility_dates = {}
        r_coverage.member_enrollments.each do |m_en|
          coverage_eligibility_dates[m_en.member_id] = m_en.coverage_eligibility_on
        end
        calc_state = CalculatorState.new(pricing_model, r_coverage, pricing_determination, coverage_eligibility_dates)
        calc_results = benefit_roster_entry.members.inject(calc_state) do |calc, mem|
          calc.add(mem)
        end
        calc_results.finalize_results
        r_coverage.member_enrollments.each do |m_en|
          m_en.product_price = calc_results.member_pricing[m_en.member_id]
        end
        r_coverage.product_cost_total = calc_results.total
        benefit_roster_entry
      end
    end
  end
end
