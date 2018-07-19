class CompositeRatedPlanCostDecorator < SimpleDelegator
  def initialize(plan, benefit_group, composite_rating_tier, cobra_status)
    super(plan)
    @plan = plan
    @benefit_group = benefit_group
    @composite_rating_tier = composite_rating_tier
    @cobra_status = cobra_status
  end

  def sole_source?
    @benefit_group.sole_source?
  end

  def employer_contribution_for(member)
    member_family_size = member.family.family_members.count
    return contribution_for_subscriber(member_family_size) if member.is_subscriber?
    return total_employer_contribution - (member_family_size - 1) * contribution_for_subscriber(member_family_size)
  end

  def employee_cost_for(member)
    member_family_size = member.family.family_members.count
    return cost_for_subscriber(member_family_size) if member.is_subscriber?
    return total_employee_cost - (member_family_size - 1) * cost_for_subscriber(member_family_size)
  end

  def premium_for(member)
    member_family_size = member.family.family_members.count
    return premium_for_subscriber(member_family_size) if member.is_subscriber?
    return total_premium - (member_family_size - 1) * premium_for_subscriber(member_family_size)
  end

  def premium_for_subscriber(member_family_size)
    (total_premium / member_family_size).round(2)
  end

  def contribution_for_subscriber(member_family_size)
    (total_employer_contribution / member_family_size).round(2)
  end

  def cost_for_subscriber(member_family_size)
    (total_employee_cost / member_family_size).round(2)
  end

  def total_premium
    @total_premium ||= @benefit_group.composite_rating_tier_premium_for(@composite_rating_tier)
  end

  def total_employer_contribution
    return 0.00 if @cobra_status
    (total_premium * employer_contribution_factor).round(2)
  end

  def total_employee_cost
    (total_premium - total_employer_contribution).round(2)
  end

  def self.benefit_relationship(person_relationship)
    {
      "head of household" => nil,
      "spouse" => "family",
      "ex-spouse" => "family",
      "cousin" => nil,
      "ward" => "family",
      "trustee" => "family",
      "annuitant" => nil,
      "other relationship" => nil,
      "other relative" => nil,
      "self" => "employee_only",
      "parent" => nil,
      "grandparent" => nil,
      "aunt_or_uncle" => nil,
      "nephew_or_niece" => nil,
      "father_or_mother_in_law" => nil,
      "daughter_or_son_in_law" => nil,
      "brother_or_sister_in_law" => nil,
      "adopted_child" => "family",
      "stepparent" => nil,
      "foster_child" => "family",
      "sibling" => nil,
      "stepchild" => "family",
      "sponsored_dependent" => "family",
      "dependent_of_a_minor_dependent" => nil,
      "guardian" => nil,
      "court_appointed_guardian" => nil,
      "collateral_dependent" => "family",
      "life_partner" => "family",
      "child" => "family",
      "grandchild" => nil,
      "unrelated" => nil,
      "great_grandparent" => nil,
      "great_grandchild" => nil,
    }[person_relationship]
  end

  def employer_contribution_factor
    @benefit_group.composite_employer_contribution_factor_for(@composite_rating_tier)
  end
end
