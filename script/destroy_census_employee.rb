census_employees = CensusEmployee.where(first_name: 'Dwaine', last_name: 'Carr')

if census_employees.size !=1
  puts "Found No/more than 1 census Employees"
else
  ce = census_employees.first
  employee_role_id = ce.employee_role.id
  person = ce.employee_role.person
  incorrect_shop_enrollments = person.primary_family.active_household.hbx_enrollments.select { |enr| enr.employee_role_id == employee_role_id}
  incorrect_shop_enrollments.collect { |enr| enr.destroy! }
  puts "Destroyed Incorrect Shop Enrollments"
  person.employee_roles.where(id: employee_role_id).first.destroy!
  puts "Destroyed Employee Role"
  ce.destroy!
  puts "Destroyed Census Employee"
end
