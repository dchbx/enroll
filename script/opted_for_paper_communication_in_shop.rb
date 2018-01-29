organizations = Organization.where(employer_profile: {:$exists=> true})

batch_size = 500
offset = 0
org_count = organizations.count

employer_csv = CSV.open("employers_opted_for_paper_communication_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
employer_csv << %w(legal_name fein communication_preference)

employee_csv = CSV.open("employees_opted_for_paper_communication_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
employee_csv << %w(hbx_id consumer first_name last_name home_email work_email group_name fein communication_preference)

def add_to_employer_csv(employer_csv, employer)
  employer_csv << [employer.legal_name, employer.fein, employer.contact_method]
end

def add_to_employee_csv(employee_csv, census_employee, employer, person)
  employee_csv << [person.hbx_id, person.has_active_consumer_role?, person.first_name, person.last_name, person.home_email.try(:address), person.work_email.try(:address), employer.legal_name, employer.fein, census_employee.employee_role.contact_method]
end

while offset < org_count
  organizations.offset(offset).limit(batch_size).each do |org|
    begin
      employer = org.employer_profile
      add_to_employer_csv(employer_csv, employer)
      employer.census_employees.active.each do |ce|
        if ce.employee_role.present? && ce.employee_role.person
          person = ce.employee_role.person
          add_to_employee_csv(employee_csv, ce, employer, person)
        end
      end
    rescue => e
      puts "Error found for #{org.legal_name}" + e.message + "   " + e.backtrace.first
    end
  end
  offset = offset + batch_size
end