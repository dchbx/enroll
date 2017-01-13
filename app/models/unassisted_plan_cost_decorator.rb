class UnassistedPlanCostDecorator < SimpleDelegator
  attr_reader :member_provider
  attr_reader :elected_aptc
  attr_reader :tax_household

  def initialize(plan, hbx_enrollment, elected_aptc=0, tax_household=nil)
    super(plan)
    @member_provider = hbx_enrollment
    @elected_aptc = elected_aptc.to_f
    @tax_household = tax_household
  end

  def members
    member_provider.hbx_enrollment_members
  end

  def schedule_date
    @member_provider.effective_on
  end

  def age_of(member)
    member.age_on_eligibility_date
  end

  def child_index(member)
    @children = members.select(){|member| age_of(member) < 21} unless defined?(@children)
    @children.index(member)
  end

  def large_family_factor(member)
    if (age_of(member) > 20) || (coverage_kind == "dental")
      1.00
    else
      if child_index(member) > 2
        0.00
      else
        1.00
      end
    end
  end

  def premium_for(member)
    (Caches::PlanDetails.lookup_rate(__getobj__.id, schedule_date, age_of(member)) * large_family_factor(member)).round(2)
  end

  def employer_contribution_for(member)
    0.00
  end

  def aptc_amount(member)
    if @tax_household.present?
      aptc_available_hash = @tax_household.aptc_available_amount_for_enrollment(@member_provider, __getobj__, @elected_aptc)
      ((aptc_available_hash[member.applicant_id.to_s].try(:to_f) || 0) * large_family_factor(member)).round(2)
    else
      0.00
    end
  end

  def employee_cost_for(member)
    cost = (premium_for(member) - aptc_amount(member)).round(2)
    cost = 0.00 if cost < 0
    (cost * large_family_factor(member)).round(2)
  end

  def total_premium
    members.reduce(0.00) do |sum, member|
      (sum + premium_for(member)).round(2)
    end
  end

  def total_employer_contribution
    0.00
  end

  def total_aptc_amount
    members.reduce(0.00) do |sum, member|
      (sum + aptc_amount(member)).round(2)
    end.round(2)
  end

  def total_employee_cost
    members.reduce(0.00) do |sum, member|
      (sum + employee_cost_for(member)).round(2)
    end.round(2)
  end
end
