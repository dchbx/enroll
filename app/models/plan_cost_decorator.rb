class PlanCostDecorator < SimpleDelegator
  attr_reader :member_provider, :benefit_group, :reference_plan

  include ShopPolicyCalculations

  def initialize(plan, member_provider, benefit_group, reference_plan, max_cont_cache = {})
    super(plan)
    @member_provider = member_provider
    @benefit_group = benefit_group
    @reference_plan = reference_plan
    @max_contribution_cache = max_cont_cache
  end

  def plan_year_start_on
    #FIXME only for temp ivl
    if @benefit_group.present?
      benefit_group.plan_year.start_on
    else
      TimeKeeper.date_of_record.beginning_of_year
    end
  end

  def child_index(member)
    @children = members.select(){|member| age_of(member) < 21} unless defined?(@children)
    @children.index(member)
  end

  def self.benefit_relationship(person_relationship)
    {
      "head of household" => nil,
      "spouse" => "spouse",
      "ex-spouse" => "spouse",
      "cousin" => nil,
      "ward" => "child_under_26",
      "trustee" => "child_under_26",
      "annuitant" => nil,
      "other relationship" => nil,
      "other relative" => nil,
      "self" => "employee",
      "parent" => nil,
      "grandparent" => nil,
      "aunt_or_uncle" => nil,
      "nephew_or_niece" => nil,
      "father_or_mother_in_law" => nil,
      "daughter_or_son_in_law" => nil,
      "brother_or_sister_in_law" => nil,
      "adopted_child" => "child_under_26",
      "stepparent" => nil,
      "foster_child" => "child_under_26",
      "sibling" => nil,
      "stepchild" => "child_under_26",
      "sponsored_dependent" => "child_under_26",
      "dependent_of_a_minor_dependent" => nil,
      "guardian" => nil,
      "court_appointed_guardian" => nil,
      "collateral_dependent" => "child_under_26",
      "life_partner" => "domestic_partner",
      "child" => "child_under_26",
      "grandchild" => nil,
      "unrelated" => nil,
      "great_grandparent" => nil,
      "great_grandchild" => nil,
    }[person_relationship]
  end

  def relationship_benefit_for(member)
    relationship = relationship_for(member)
    @reference_plan.coverage_kind == 'dental' ? benefit_group.dental_relationship_benefit_for(relationship) : benefit_group.relationship_benefit_for(relationship)
  end

  def employer_contribution_percent(member)
    relationship_benefit = relationship_benefit_for(member)
    if relationship_benefit && relationship_benefit.offered?
      relationship_benefit.premium_pct
    else
      0.00
    end
  end

  def reference_plan_member_premium(member)
    Caches::PlanDetails.lookup_rate(reference_plan.id, plan_year_start_on, age_of(member))
  end

  def reference_premium_for(member)
    # FIXME: I've just fixed this to use the plan rate cache - it seems there
    #        multiple areas where this isn't being used - we need to correct this.
    (reference_plan_member_premium(member) * large_family_factor(member)).round(2)
  rescue
    0.00
  end

  def premium_for(member)
    relationship_benefit = relationship_benefit_for(member)
    if relationship_benefit && relationship_benefit.offered?
      value = (Caches::PlanDetails.lookup_rate(__getobj__.id, plan_year_start_on, age_of(member)) * large_family_factor(member))
      BigDecimal.new("#{value}").round(2).to_f
    else
      0.00
    end
  end

  def max_employer_contribution(member)
    return @max_contribution_cache.fetch(member._id) if @max_contribution_cache.has_key?(member._id)
    @max_contribution_cache[member._id] = ((large_family_factor(member) * (reference_premium_for(member) * employer_contribution_percent(member))) / 100.00).round(2)
  end

  def employer_contribution_for(member)
    ([max_employer_contribution(member), premium_for(member)].min * large_family_factor(member)).round(2)
  end

  def employee_cost_for(member)
    (if @benefit_group.present?
      premium_for(member) - employer_contribution_for(member)
    else
      __getobj__.premium_for(plan_year_start_on, age_of(member))
    end * large_family_factor(member)).round(2)
  end

  def total_employer_contribution
    (members.reduce(0.00) do |sum, member|
      (sum + employer_contribution_for(member)).round(2)
    end).round(2)
  end

  def total_employee_cost
    (members.reduce(0.00) do |sum, member|
      (sum + employee_cost_for(member)).round(2)
    end).round(2)
  end
end
