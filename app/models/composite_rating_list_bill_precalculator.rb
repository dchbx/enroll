class CompositeRatingListBillPrecalculator < SimpleDelegator
  attr_reader :member_provider, :benefit_group, :plan

  include ShopPolicyCalculations

  def initialize(plan, member_provider, benefit_group)
    super(plan)
    @member_provider = member_provider
    @benefit_group = benefit_group
    @plan = plan
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

  def premium_for(member)
      value = (Caches::PlanDetails.lookup_rate_with_area(__getobj__.id, plan_year_start_on, age_of(member), benefit_group.rating_area) * large_family_factor(member))
      adjusted_value = value * benefit_group.sic_factor_for(plan) * benefit_group.group_size_factor_for(plan) * benefit_group.composite_participation_rate_factor_for(plan)
      BigDecimal.new("#{adjusted_value}").round(2).to_f
  end
end
