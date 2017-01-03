Given(/(.*) is newly designated/) do |named_person|
  person = people[named_person]

  census_employee = CensusEmployee.where(first_name: person[:first_name], last_name: person[:last_name]).first
  census_employee.newly_designate!

  census_employee.employer_profile.plan_years.each do |plan_year|
    plan_year.benefit_groups.each do |benefit_group|
      benefit_group.effective_on_kind = 'first_of_month'
      benefit_group.effective_on_offset = 1
      benefit_group.is_congress = true
    end
    plan_year.save!
  end
end