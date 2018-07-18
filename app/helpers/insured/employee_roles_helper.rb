module Insured::EmployeeRolesHelper
  def employee_role_submission_options_for(model)
    if model.persisted?
      { :url => insured_employee_path(model), :method => :put }
    else
      { :url => insured_employee_index_path, :method => :post }
    end
  end

  def coverage_relationship_check(offered_relationship_benefits=[], family_member, new_effective_on )
    return nil if offered_relationship_benefits.blank?
    relationship = PlanCostDecorator.benefit_relationship(family_member.primary_relationship)
    if relationship == "child_under_26" && (calculate_age_by_dob(family_member.dob) > 26 || (new_effective_on.kind_of?(Date) && new_effective_on >= family_member.dob+26.years))
      relationship = "child_over_26"
    end

    offered_relationship_benefits.include? relationship
  end

  def composite_relationship_check(offered_relationship_benefits=[], family_member, new_effective_on)
    return nil if offered_relationship_benefits.blank?
    direct_realation_to_primary = family_member.primary_relationship

    relationship = CompositeRatedPlanCostDecorator.benefit_relationship(direct_realation_to_primary)
    if direct_realation_to_primary == "child" && calculate_age_by_dob(family_member.dob) >= 26 && new_effective_on >= family_member.dob+26.years
      relationship = "child_over_26"
    end

    offered_relationship_benefits.include? relationship
  end

  def show_market_name_by_enrollment(enrollment)
    return '' if enrollment.blank?

    if enrollment.is_shop?
      enrollment.is_cobra_status? ? 'Employer Sponsored COBRA/Continuation' : 'Employer Sponsored'
    else
      'Individual'
    end
  end
end
