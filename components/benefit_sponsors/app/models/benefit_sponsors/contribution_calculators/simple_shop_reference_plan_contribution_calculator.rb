module BenefitSponsors
  module ContributionCalculators
    class SimpleShopReferencePlanContributionCalculator < ContributionCalculator
      class CalculatorState
        attr_reader :total_contribution
        attr_reader :member_contributions

        def initialize(c_model, m_prices, r_coverage, r_product, l_map, c_eligibility_dates, contribution_banhammered)
          @rate_schedule_date = r_coverage.rate_schedule_date
          @contribution_model = c_model
          @contribution_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
          @total_contribution = 0.00
          @member_prices = m_prices
          @member_contributions = {}
          @reference_product = r_product
          @eligibility_dates = c_eligibility_dates
          @coverage_start_on = r_coverage.coverage_start_on
          @rating_area = r_coverage.rating_area
          @level_map = l_map
          @product = r_coverage.product
          @previous_product = r_coverage.previous_product
          @is_contribution_prohibited = contribution_banhammered
        end

        def add(member)
          if !@is_contribution_prohibited
            c_factor = contribution_factor_for(member)
            c_amount = calc_contribution_amount_for(member, c_factor)
            @member_contributions[member.member_id] = c_amount 
            @total_contribution = BigDecimal.new((@total_contribution + c_amount).to_s).round(2)
          else
            @member_contributions[member.member_id] = 0.00
          end
          self
        end

        def calc_contribution_amount_for(member, c_factor)
          member_price = @member_prices[member.member_id]
          if (member_price == 0.00) || (c_factor == 0)
            0.00
          end
          ref_rate = reference_rate_for(member)
          ref_contribution = BigDecimal.new((ref_rate * c_factor).to_s).round(2)
          if member_price <= ref_contribution
            member_price
          else
            ref_contribution
          end
        end

        def reference_rate_for(member)
          ::BenefitMarkets::Products::ProductRateCache.lookup_rate(
            @reference_product,
            @rate_schedule_date,
            @contribution_calculator.calc_coverage_age_for(member, @product, @coverage_start_on, @eligibility_dates, @previous_product),
            @rating_area
          )
        end

        def contribution_factor_for(roster_entry_member)
          cu = get_contribution_unit(roster_entry_member)
          cl = @level_map[cu.id]
          cl.contribution_factor
        end

        def get_contribution_unit(roster_entry_member)
          coverage_age = @contribution_calculator.calc_coverage_age_for(roster_entry_member, @product, @coverage_start_on, @eligibility_dates, @previous_product)
          relationship = roster_entry_member.is_primary_member? ? "self" : roster_entry_member.relationship
          rel_name = @contribution_model.map_relationship_for(relationship, coverage_age, roster_entry_member.is_disabled?)
          @contribution_model.contribution_units.detect do |cu|
            cu.match?({rel_name.to_s => 1})
          end
        end
      end

      def initialize
        @level_map = {}
      end

      # Calculate contributions for the given entry
      # @param contribution_model [BenefitMarkets::ContributionModel] the
      #   contribution model for this calculation
      # @param priced_roster_entry [BenefitMarkets::SponsoredBenefits::PricedRosterEntry]
      #   the roster entry for which to provide contribution
      # @param sponsor_contribution [BenefitSponsors::SponsoredBenefits::SponsorContribution]
      #   the concrete values for contributions
      # @return [BenefitMarkets::SponsoredBenefits::ContributionRosterEntry] the
      #   contribution results paired with the roster
      def calculate_contribution_for(contribution_model, priced_roster_entry, sponsor_contribution)
        reference_product = sponsor_contribution.reference_product
        roster_coverage = priced_roster_entry.group_enrollment
        level_map = level_map_for(sponsor_contribution)
        coverage_eligibility_dates = {}
        roster_coverage.member_enrollments.each do |m_en|
          coverage_eligibility_dates[m_en.member_id] = m_en.coverage_eligibility_on
        end
        member_pricing = {}
        roster_coverage.member_enrollments.each do |m_en|
          member_pricing[m_en.member_id] = m_en.product_price
        end
        state = CalculatorState.new(
          contribution_model,
          member_pricing,
          roster_coverage,
          reference_product,
          level_map,
          coverage_eligibility_dates,
          roster_coverage.sponsor_contribution_prohibited
        )
        priced_roster_entry.members.each do |member|
          state.add(member)
        end
        roster_coverage.sponsor_contribution_total = state.total_contribution
        roster_coverage.member_enrollments.each do |m_en|
          m_en.sponsor_contribution = state.member_contributions[m_en.member_id]
        end
        priced_roster_entry
      end

      protected

      def level_map_for(sponsor_contribution)
        @level_map[sponsor_contribution.id] ||= sponsor_contribution.contribution_levels.inject({}) do |acc, cl|
          acc[cl.contribution_unit_id] = cl
          acc
        end
      end
    end
  end
end
