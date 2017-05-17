#data-15126
ce = CensusEmployee.where(id: '561c5a6c54726501f3280300').first
ce.benefit_group_assignments[0].update_attributes(hbx_enrollment_id: '')
ce.benefit_group_assignments[1].update_attributes(start_on: '2017-05-01 00:00:00 UTC')
ce.benefit_group_assignments[1].update_attributes(end_on: '2018-04-30 00:00:00 UTC')


ce1 = CensusEmployee.where(id: '561c5a6c54726501f3310300').first
ce1.benefit_group_assignments[0].update_attributes(hbx_enrollment_id: '')

ce2 = CensusEmployee.where(id: '58a32054faca14616a000043').first
ce2.benefit_group_assignments[0].update_attributes(start_on: '2017-05-01 00:00:00 UTC')

#bug-15128
er=Organization.where(fein:"541796172").first
er.employer_profile.census_employees.each do |a| 
  a.benefit_group_assignments.first.update_attributes(start_on: Date.new(2017,5,1))
end

#bug-15127
er1=Organization.where(fein:"462387716").first
er1.employer_profile.census_employees.each do |a| 
  a.benefit_group_assignments.first.update_attributes(start_on: Date.new(2017,5,1))
end
 
#data-14390
er=Organization.where(fein:"800389609").first
er.employer_profile.census_employees.each do |a| 
  a.benefit_group_assignments.first.update_attributes(start_on: Date.new(2017,4,1))
end