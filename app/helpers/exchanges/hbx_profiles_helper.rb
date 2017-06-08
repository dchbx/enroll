module  Exchanges::HbxProfilesHelper

  def can_cancel_employer_plan_year?(employer_profile)
    ['published', 'enrolling', 'enrolled'].include?(employer_profile.active_plan_year.aasm_state)
  end

end