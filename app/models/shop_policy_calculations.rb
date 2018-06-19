module ShopPolicyCalculations

  def age_of(member)
    case member.class
    when HbxEnrollmentMember
      member.age_on_effective_date
    else
      member.age_on(plan_year_start_on)
    end
  end

  def members
    case member_provider.class
    when HbxEnrollment
      member_provider.hbx_enrollment_members
    when CensusEmployee
      [member_provider] + member_provider.census_dependents
    when QuoteHousehold
      member_provider.quote_members
    when SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee
      [member_provider] + member_provider.census_dependents
    end
  end

  def benefit_relationship(person_relationship)
    PlanCostDecorator.benefit_relationship(person_relationship)
  end

  def total_premium
    members.reduce(0.00) do |sum, member|
      (sum + premium_for(member)).round(2)
    end.round(2)
  end

  def large_family_factor(member)
    if age_of(member) > 20
      1.00
    else
      if child_index(member) > 2 && @plan.health?
        0.00
      else
        1.00
      end
    end
  end

  def relationship_for(member)
    case member.class
    when HbxEnrollmentMember
      if member.is_subscriber?
        "employee"
      else
        benefit_relationship(member.primary_relationship)
      end
    when SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee
      'employee'
    else
      member.employee_relationship
    end
  end

end
