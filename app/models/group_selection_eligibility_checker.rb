# This class allows us to check eligibilty for family members.
# It is only a partial fix until we fully correct the group selection page
# to be aware of how composite rating can include/exclude members.
# It does NOT function correctly in the individual market.
class GroupSelectionEligibilityChecker
  MemberAgeSlug = Struct.new(:dob, :member_id)

  def initialize(benefit_package, coverage_kind)
    if benefit_package.present?
      @sponsored_benefit = benefit_package.sponsored_benefits.detect do |sb|
        sb.product_kind.to_s == coverage_kind.to_s
      end
    end
    @contribution_model = @sponsored_benefit.contribution_model if @sponsored_benefit.present?
    @age_calculator = ::BenefitSponsors::CoverageAgeCalculator.new
  end

  def can_cover?(family_member, coverage_date)
    return false if @sponsored_benefit.blank?
    rel, disability, dob = map_family_member_data(family_member)
    return true if (rel.to_s == "self")
    return false if dob > coverage_date
    coverage_age = @age_calculator.calc_coverage_age_for(MemberAgeSlug.new(dob, family_member.id), nil, coverage_date, {}, nil)
    # If the relationship doesn't even map, they aren't allowed
    mapped_relationship = @contribution_model.map_relationship_for(rel, coverage_age, disability)
    member_relationship = @contribution_model.member_relationship_for(rel, coverage_age, disability)
    return false if mapped_relationship.blank?
    return false if member_relationship.blank?
    return false if mapped_relationship.to_s == 'dependent' && member_eligible_for_coverage?(coverage_date, family_member, rel)
    matching_contribution_units = @contribution_model.contribution_units.select do |cu|
      cu.at_least_one_matches?({mapped_relationship.to_s => 1})
    end
    return false if matching_contribution_units.empty?
    cu_ids = matching_contribution_units.map(&:id)
    matching_contribution_levels = @sponsored_benefit.sponsor_contribution.contribution_levels.select do |cl|
      cu_ids.include?(cl.contribution_unit_id)
    end
    return false if matching_contribution_levels.empty?
    matching_contribution_levels.any?(&:is_offered?)
  end

  def map_family_member_data(family_member)
    rel = family_member.is_primary_applicant? ? "self" : family_member.relationship
    disability = family_member.person.is_disabled
    dob = family_member.person.dob
    [rel, disability, dob]
  end

  def member_eligible_for_coverage?(coverage_date, family_member, rel)
    market_key = @sponsored_benefit.reference_product.benefit_market_kind == :aca_shop ? :aca_shop_dependent_age_off : :aca_fehb_dependent_age_off
    if EnrollRegistry.feature_enabled?(:age_off_relaxed_eligibility)
      return false unless EnrollRegistry[market_key].setting(:relationship_kinds).item.include?(rel)
      dependent_coverage_eligible = ::EnrollRegistry[:age_off_relaxed_eligibility] do
        {
          effective_on: coverage_date,
          family_member: family_member,
          market_key: market_key,
          relationship_kind: rel
        }
      end
      dependent_coverage_eligible.success? ? false : true
    else
      member_relationship.age_comparison.to_s == ">="
    end
  end
end
