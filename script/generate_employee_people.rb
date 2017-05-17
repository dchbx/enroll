def add_employee_role(user: nil, employer_profile:,
                           name_pfx: nil, first_name:, middle_name: nil, last_name:, name_sfx: nil,
                           ssn:, dob:, gender:, hired_on:,
                           census_employee:
                          )
  person, person_new = Factories::EnrollmentFactory.initialize_person(user, name_pfx, first_name, middle_name,
                                         last_name, name_sfx, ssn, dob, gender, "employee")

  Factories::EnrollmentFactory.build_employee_role(
    person, person_new, employer_profile, census_employee, hired_on
  )
end

def create_people_for_employer(fein)
  employer = Organization.where(fein: fein).first.employer_profile

  employer.census_employees.non_terminated.each do |ce|
    puts "  renewing: #{ce.full_name}"
    begin
      person = Person.where(encrypted_ssn: Person.encrypt_ssn(ce.ssn)).first

      if person.blank?
        employee_role, family = add_employee_role({
          first_name: ce.first_name,
          last_name: ce.last_name,
          ssn: ce.ssn, 
          dob: ce.dob,
          employer_profile: employer,
          gender: ce.gender,
          hired_on: ce.hired_on,
          census_employee: ce
        })
        puts "created person record for #{ce.full_name}"
      else
        family = person.primary_family
      end
    rescue Exception => e
      puts "Renewal failed for #{ce.full_name} due to #{e.to_s}"
    end
  end
end

feins = %w(
)

feins.each do |fein|
  create_people_for_employer(fein)
end
