module  Exchanges::HbxProfilesHelper

  def latest_terminated_plan_year(employer_profile)
    employer_profile.plan_years.select do |plan_year|
      plan_year.terminated?
    end.sort_by do |plan_year|
      plan_year.start_on
    end.last
  end
end