module Insured::EmployeeRolesHelper
  def employee_role_submission_options_for(model)
    if model.persisted?
      { :url => insured_employee_path(model), :method => :put }
    else
      { :url => insured_employee_index_path, :method => :post }
    end
  end

  def coverage_relationship_check(offered_relationship_benefits=[], family_member)
    relationship = PlanCostDecorator.benefit_relationship(family_member.primary_relationship)
    return relationship if relationship == "employee"
    if ['child','child_under_26' ,'child_over_26','grandchild','nephew_or_niece'].include?(relationship)
      age = calculate_age_by_dob(family_member.dob)
      if (age >= 26 && family_member.is_disabled)  || (age < 26 && family_member.has_primary_caregiver)
        return relationship
      end
    elsif offered_relationship_benefits.include?(relationship)
      return relationship
    end
  end

end
