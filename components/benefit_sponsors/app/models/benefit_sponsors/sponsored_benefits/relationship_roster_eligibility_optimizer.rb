module BenefitSponsors
  module SponsoredBenefits
    # Takes a 'naked' roster entry with possible coverage information and
    # calculates which the 'optimal' available enrollment options for
    # that group, as well as which members will be excluded.
    #
    # This will typically be used against a set of roster employees
    # in order to determine how to calculate 'estimated'
    # rates prior to having actual enrollments available.
    class RelationshipRosterEligibilityOptimizer
      class OptimizerState
        attr_reader :excluded_dependent_ids

        def initialize(c_model, level_map, elig_dates, c_start, c_product, c_previous_product, primary_id)
          @offered_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
          @eligibility_dates = elig_dates
          @coverage_start = c_start
          @level_map = level_map
          @contribution_model = c_model
          @relationship_totals = Hash.new(0)
          @product = c_product
          @previous_product = c_previous_product
          @excluded_dependent_ids = []
          @member_rels = {}
          @member_dobs = {}
          @member_ids = []
          @primary_id = primary_id
        end

        def add(member)
          coverage_age = @offered_calculator.calc_coverage_age_for(member, @product, @coverage_start, @eligibility_dates, @previous_product)
          # In shop, survivors are treated as the employee
          member_relationship = member.is_primary_member? ? "self" : member.relationship
          rel_name = @contribution_model.map_relationship_for(member_relationship, coverage_age, member.is_disabled?)
          if rel_name
            @relationship_totals[rel_name.to_s] = @relationship_totals[rel_name] + 1
            @member_rels[member.member_id] = rel_name
            @member_dobs[member.member_id] = member.dob
            contribution_unit = @contribution_model.contribution_units.detect do |cu|
              cu.match?({rel_name.to_s => 1})
            end
            cu = @level_map[contribution_unit.id]
            if cu.is_offered
              @member_ids << member.member_id
              return self
            end
          end
          @excluded_dependent_ids = @excluded_dependent_ids + [member.member_id]
          self
        end
      end

      def initialize
        @level_map = {}
      end

      # Note that the sponsor contribution is needed because it stores the
      # corresponding levels and 'offered?' flag.
      def calculate_optimal_group_for(contribution_model, covered_roster_entry, sponsor_contribution)
        level_map = level_map_for(sponsor_contribution)
        roster_coverage = covered_roster_entry.group_enrollment
        coverage_eligibility_dates = {}
        roster_coverage.member_enrollments.each do |m_en|
          coverage_eligibility_dates[m_en.member_id] = m_en.coverage_eligibility_on
        end
        state = OptimizerState.new(contribution_model, level_map, coverage_eligibility_dates, roster_coverage.coverage_start_on, roster_coverage.product, roster_coverage.previous_product, covered_roster_entry.primary_member.member_id)
        covered_roster_entry.members.each do |member|
          state.add(member)
        end
        covered_roster_entry.reject! { |m| state.excluded_dependent_ids.include?(m.member_id) }
        covered_roster_entry
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
