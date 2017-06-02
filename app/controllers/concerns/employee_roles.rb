module EmployeeRoles
  def set_notice_preference(person, employee_role)
    other_active_employee_roles = person.active_employee_roles.select {|er| er.id != employee_role.id}
    other_active_employee_roles.each { |er| er.update_attributes(contact_method: employee_role.contact_method, language_preference: employee_role.language_preference)}
  end
end
