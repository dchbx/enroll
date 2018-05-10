class PlanCostDecoratorCongress < SimpleDelegator
  attr_reader :member_provider, :benefit_group, :reference_plan

  include ShopPolicyCalculations

  def initialize(plan, member_provider, benefit_group, max_cont_cache = {})
    super(plan)
    @member_provider = member_provider
    @benefit_group = benefit_group
    @max_contribution_cache = max_cont_cache
    @plan = plan
  end

  def sole_source?
    false
  end
  
  def plan_year_start_on
    benefit_group.plan_year.start_on
  end

  def child_index(member)
    @children = members.select(){|member| age_of(member) < 21 && relationship_for(member) == "child_under_26"} unless defined?(@children)
    @children.index(member) || -1
  end

  def member_index(member)
    members.index(member)
  end

  def employer_contribution_percent
    benefit_group.contribution_pct_as_int
  end

  def total_max_employer_contribution
    case members.size
    when 0
      0.to_money
    when 1
      benefit_group.employee_max_amt
    when 2
      benefit_group.first_dependent_max_amt
    else
      benefit_group.over_one_dependents_max_amt
    end
  end

  def premium_for(member)
    # Caches::PlanDetails.lookup_rate(__getobj__.id, plan_year_start_on, age_of(member)) * large_family_factor(member)
    (Caches::PlanDetails.lookup_rate(__getobj__.id, plan_year_start_on, age_of(member)) * large_family_factor(member)).round(2)
  end

  def employer_contribution_for(member)
    return 0 if @member_provider.present? && @member_provider.is_cobra_status?
    (total_employer_contribution * (premium_for(member)/total_premium)).round(2)
    # premium_for(member) * ( total_employer_contribution / total_premium )
  end

  def employee_cost_for(member)
    premium_for(member) - employer_contribution_for(member)
  end

  def total_employer_contribution
    return 0 if @member_provider.present? && @member_provider.is_cobra_status?
    ([total_premium * employer_contribution_percent / 100.00, total_max_employer_contribution.cents/100.00].min).round(2)
  end

  def total_employee_cost
    (members.reduce(0.00) do |sum, member|
      (sum + premium_for(member)).round(2)
    end) - total_employer_contribution
  end
end
