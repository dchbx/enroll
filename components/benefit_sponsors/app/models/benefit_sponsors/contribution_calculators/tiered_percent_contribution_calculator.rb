module BenefitSponsors
  module ContributionCalculators
    class TieredPercentContributionCalculator < ContributionCalculator
      class CalculatorState
        attr :total_contribution
        attr :member_contributions

        def initialize(c_model, level_map, t_price, elig_dates, c_start, r_coverage, contribution_banhammered)
          @contribution_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
          @eligibility_dates = elig_dates
          @coverage_start = c_start
          @level_map = level_map
          @contribution_model = c_model
          @relationship_totals = Hash.new(0)
          @member_total = 0
          @member_ids = []
          @total_price = t_price
          @total_contribution = 0.00
          @member_contributions = {}
          @product = r_coverage.product
          @previous_product = r_coverage.previous_product
          @primary_member_id = nil
          @is_contribution_prohibited = contribution_banhammered
        end

        def add(member)
          if member.is_primary_member?
            @primary_member_id = member.member_id
          end
          coverage_age = @contribution_calculator.calc_coverage_age_for(member, @product, @coverage_start, @eligibility_dates, @previous_product)
          relationship = member.is_primary_member? ? "self" : member.relationship
          rel_name = @contribution_model.map_relationship_for(relationship, coverage_age, member.is_disabled?)
          @relationship_totals[rel_name.to_s] = @relationship_totals[rel_name] + 1
          @member_total = @member_total + 1
          @member_ids = @member_ids + [member.member_id]
          self
        end

        def finalize_results
          if !@is_contribution_prohibited
            contribution_unit = @contribution_model.contribution_units.detect do |cu|
              cu.match?(@relationship_totals)
            end
            cu = @level_map[contribution_unit.id]
            c_factor = cu.contribution_factor
            max_contribution = BigDecimal.new((@total_price * c_factor).to_s).round(2)
            @total_contribution = [max_contribution, @total_price].min
            members_total_price = 0.00
            @member_ids.each do |m_id|
              member_price = BigDecimal.new((@total_contribution / @member_total).to_s).floor(2)
              members_total_price = BigDecimal.new((members_total_price + member_price).to_s).round(2)
              @member_contributions[m_id] = member_price
            end
            member_discrepency = BigDecimal.new((@total_contribution - members_total_price).to_s).round(2)
            @member_contributions[@primary_member_id] = BigDecimal.new((@member_contributions[@primary_member_id] + member_discrepency).to_s).round(2) 
          else
            @member_ids.each do |m_id|
              @member_contributions[m_id] = 0.00
              @total_contribution = 0.00
            end
          end
          self
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
        roster_coverage = priced_roster_entry.group_enrollment
        coverage_eligibility_dates = {}
        roster_coverage.member_enrollments.each do |m_en|
          coverage_eligibility_dates[m_en.member_id] = m_en.coverage_eligibility_on
        end
        level_map = level_map_for(sponsor_contribution)
        state = CalculatorState.new(contribution_model, level_map, roster_coverage.product_cost_total, coverage_eligibility_dates, roster_coverage.coverage_start_on, roster_coverage,roster_coverage.sponsor_contribution_prohibited)
        priced_roster_entry.members.each do |member|
          state.add(member)
        end
        state.finalize_results
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
