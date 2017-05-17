
# Run RAILS_ENV=production bundle exec rails r script/change_enrollment_statuses.rb
def cancel_previous(person)
  person.primary_family.active_household.hbx_enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES).to_a.each do |enr|
    enr.cancel_coverage!
    puts "cancel coverage under enrollment #{enr.hbx_id}"
  end
  person.save!
end

def enroll_coverage(hbx_id, census_employee)
  if census_employee.present?
    bga_id = census_employee.active_benefit_group_assignment.id
    bg_id = census_employee.active_benefit_group_assignment.benefit_group.id
    HbxEnrollment.by_hbx_id(hbx_id).first.update_attributes(aasm_state: 'coverage_enrolled', benefit_group_id: bg_id, benefit_group_assignment_id: bga_id)
  else
    HbxEnrollment.by_hbx_id(hbx_id).first.update_attributes(aasm_state: 'coverage_enrolled', terminated_on: nil)
  end
  puts "Enrolling coverage under enrollment #{hbx_id}"
end

person_hbx_ids = ['19826396', '19826395', '19834991']
er_id = Organization.where(legal_name: /Capitol Immigration Law Group/i).first.employer_profile.id
person_hbx_ids.each do |hbx_id|
  case hbx_id
    # Has correct effective on & plan_id's
  when '19826396'
    person = Person.where(hbx_id: '19826396').first
    census_employee = person.employee_roles.where(employer_profile_id: er_id).first.census_employee
    cancel_previous(person)
    enroll_coverage('511921', census_employee)
  when '19826395'
    person = Person.where(hbx_id: '19826395').first
    census_employee = person.employee_roles.where(employer_profile_id: er_id).first.census_employee
    cancel_previous(person)
    enroll_coverage('511922', census_employee)
  when '19834991'
    person = Person.where(hbx_id: '19834991').first
    cancel_previous(person)
    enroll_coverage('521494', nil)
  end
end

