module  Exchanges::HbxProfilesHelper

  def can_cancel_employer_plan_year?(employer_profile)
    ['published', 'enrolling', 'enrolled'].include?(employer_profile.active_plan_year.aasm_state)
  end

  def employee_eligibility_status(enrollment)
    if enrollment.is_shop? && enrollment.benefit_group_assignment.present?
      if enrollment.benefit_group_assignment.census_employee.can_be_reinstated?
        enrollment.benefit_group_assignment.census_employee.aasm_state.camelcase
      end
    end
  end
end
