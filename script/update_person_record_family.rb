#The Script is to update the person id on Family Record so that it point towards the right person.

enrollment_ids = [ "107403","107410","107319","107377","107328","107335","106780","107261"]

enrollment_ids.each do |id|
  enrollment = HbxEnrollment.by_hbx_id(id).first
  correct_person_id = enrollment.census_employee.employee_role.person.id
  family_record = enrollment.family_members.detect{ |family| family.is_primary_applicant == true}
  incorrect_person_id = family_record.person_id
  if (incorrect_person_id != correct_person_id)
  family_record.update_attributes!(person_id: correct_person_id)
  puts "Updating Family Record pointing towards correct person"
  else
  puts "Family Record pointing towrads correct person"
  end
end
