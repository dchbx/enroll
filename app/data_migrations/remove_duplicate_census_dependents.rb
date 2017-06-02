require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDuplicateCensusDependents < MongoidMigrationTask
  def migrate

    # Remove these persons as they are duplicates, unable to update census employee because census employee object has duplicate census dependents.
    person_1 = Person.find("58472c2ff1244e786b00010b").destroy
    person_2 = Person.find("58472c4bfaca140cfa00009f").destroy
    person_3 = Person.find("58472c01f1244e2b2b000041").destroy

    # find the enrollee and update its person relationships with proper person ids, remove the consumer role, because this person does not have any consumer role defined yet
    person = Person.where(hbx_id: /19893619/).last
    person.person_relationships.where(id: "58472c01f1244e2b2b000044").first.relative_id = "5817c80ffaca14173500594f"
    person.person_relationships.where(id: "58472c2ff1244e786b00010e").first.relative_id = "5817c80ffaca141735005955"
    person.person_relationships.where(id: "58472c4bfaca140cfa0000a2").first.relative_id = "5817c80ffaca14173500595a"
    person.consumer_role = nil
    person.save

    # update the family member objects with proper person_ids for the dependents
    family = person.primary_family
    member_1 = family.family_members.where(id: "58472c4bfaca140cfa0000a3").first
    member_1.person_id = "5817c80ffaca14173500595a"
    member_1.save

    member_2 = family.family_members.where(id: "58472c2ff1244e786b00010f").first
    member_2.person_id = "5817c80ffaca141735005955"
    member_2.save

    member_3 = family.family_members.where(id: "58472c01f1244e2b2b000045").first
    member_3.person_id = "5817c80ffaca14173500594f"
    member_3.save

    census_employee = Person.where(first_name: person.first_name, last_name: person.last_name, ssn: person.ssn, dob: person.dob).first

    # create the employee role
    employee_relationship = Forms::EmployeeCandidate.new({first_name: census_employee.first_name,
                                                        last_name: census_employee.last_name,
                                                        ssn: census_employee.ssn,
                                                        dob: census_employee.dob.strftime("%Y-%m-%d")})
    person = employee_relationship.match_person if employee_relationship.present?

    return false if person.blank? || (person.present? &&
                                    person.has_active_employee_role_for_census_employee?(census_employee))
    Factories::EnrollmentFactory.build_employee_role(person, nil, census_employee.employer_profile, census_employee, census_employee.hired_on)

    # census_employee.link_employee_role!
  end
end
