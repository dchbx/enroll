require 'csv'

filename = "8905_migration_required_enrollments.csv"

def select_benefit_package(title, benefit_coverage_period)
  benefit_coverage_period.benefit_packages.each do |benefit_package|
    if benefit_package.title == title
      return benefit_package
    end
  end
end

def select_benefit_group_assignment(correct_benefit_group,benefit_group_assignments)
  correct_benefit_group_assignment = nil
  benefit_group_assignments.each do |benefit_group_assignment|
    if benefit_group_assignment.benefit_group_id == correct_benefit_group._id
      correct_benefit_group_assignment = benefit_group_assignment
    end
  end
  return correct_benefit_group_assignment
end

def get_all_benefit_groups(organization)
  all_benefit_groups = []
  organization.employer_profile.plan_years.each do |plan_year|
    plan_year.benefit_groups.each do |benefit_group|
      all_benefit_groups.push(benefit_group)
    end
  end
  return all_benefit_groups
end

def select_benefit_group_assignment(correct_benefit_group, census_employee)

  if census_employee.active_benefit_group_assignment.present? && census_employee.active_benefit_group_assignment.benefit_group == correct_benefit_group
    return census_employee.active_benefit_group_assignment
  end

  if match = census_employee.benefit_group_assignments.detect{|assignment| assignment.benefit_group == correct_benefit_group}
    match.make_active
    return match
  end

  return nil
end

def format_date(date)
  date = Date.strptime(date,'%m/%d/%Y')
end

def find_census_employee(subscriber_params,employer_profile)
  matched_employees = CensusEmployee.where(encrypted_ssn: CensusMember.encrypt_ssn(subscriber_params["ssn"]),
                       employer_profile_id: employer_profile._id)
  census_employee = matched_employees.non_terminated.first || matched_employees.first

  if census_employee.blank?
    census_employee = CensusEmployee.where(first_name: /#{subscriber_params["first_name"]}/i,
                         last_name: /#{subscriber_params["last_name"]}/i,
                         dob: subscriber_params["dob"],
                         employer_profile_id: employer_profile._id).first
  end
  return census_employee
end

def create_person_details(subscriber_params)
  person_details = Forms::EmploymentRelationship.new
  person_details.name_pfx = subscriber_params["name_pfx"]
  person_details.first_name = subscriber_params["first_name"]
  person_details.middle_name = subscriber_params["middle_name"]
  person_details.last_name = subscriber_params["last_name"]
  person_details.name_sfx = subscriber_params["name_sfx"]
  person_details.gender = subscriber_params["gender"]
  return person_details
end

def find_dependent(ssn,dob,first_name,middle_name,last_name)
  unless ssn.blank?
    person = Person.where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)).first
  end

  if person == nil
    person = Person.where(first_name: first_name.to_s.strip, middle_name: middle_name.to_s.strip, last_name: last_name.to_s.strip, dob: format_date(dob)).first
  else
    return person
  end

  if person == nil
    return ArgumentError.new("dependent does not exist for provided person details")
  else
    return person
  end
end

def select_employee_role(employer_profile_id, employee_roles)
  correct_employee_role = employee_roles.detect{|employee_role| employee_role.employer_profile_id == employer_profile_id}
  return correct_employee_role
end

## Just for clarification
# EnrollmentFactory#construct_consumer_role
# EnrollmentFactory#initialize_dependent
# dependent_person.build_consumer_role(is_applicant: false)
# EnrollmentFactory#construct_employee_role
# EnrollmentFactory#initialize_dependent
# dependent_person.employee_roles.build(employer_profile: employer_profile, hired_on: hired_on)

complete_rows = []


CSV.foreach(filename, headers: :true) do |row|

  # begin
  data_row = row.to_hash
  existing_enrollments = HbxEnrollment.by_hbx_id(data_row["Enrollment Group ID"])
  if existing_enrollments.size > 0
    subscriber_ids = existing_enrollments.map(&:subscriber).map(&:person).map(&:hbx_id).join(",")
    row["Error Message"] = "Enrollment with hbx_id #{data_row["Enrollment Group ID"]} already exists on"
    row["E-HBX_ID"] = "Enroll HBX ID(s): #{subscriber_ids},"
    row["G-HBX_ID"] = "Glue HBX ID: #{data_row['HBX ID']}"
    complete_rows.push(row)
    next
  end
  # subscriber = Person.where(hbx_id: data_row['HBX ID']).first
  subscriber_params = {"name_pfx" => data_row["Name Prefix"],
                   "first_name" => data_row["First Name"],
                   "middle_name" => data_row["Middle Name"],
                   "last_name" => data_row["Last Name"],
                   "name_sfx" => data_row["Name Suffix"],
                   "ssn" => data_row["SSN"].gsub("-",""),
                   "dob" => format_date(data_row["DOB"]),
                   "gender" => data_row["Gender"].downcase,
                   "no_ssn" => 0
                  }

  person_details = create_person_details(subscriber_params)
  organization = Organization.where(fein: data_row["Employer FEIN"].gsub("-","")).first

  census_employee = find_census_employee(subscriber_params,organization.employer_profile)
  if census_employee == nil
    row["Error Message"] = "Cannot find Census Employee #{subscriber_params["first_name"]} #{subscriber_params["last_name"]}"
    complete_rows.push(row)
    next
  end
  census_dependents = []
  6.times do |i|
    next unless data_row["Enrollee End Date (Dep #{i+1})"].blank?
    if data_row["HBX ID (Dep #{i+1})"].present?
      census_dependents << CensusDependent.new({
        first_name: data_row["First Name (Dep #{i+1})"],
        middle_name: data_row["Middle Name (Dep #{i+1})"],
        last_name: data_row["Last Name (Dep #{i+1})"],
        dob: format_date(data_row["DOB (Dep #{i+1})"]),
        employee_relationship: data_row["Relationship (Dep #{i+1})"].strip == 'child' ? 'child_under_26' : data_row["Relationship (Dep #{i+1})"].strip,
        gender:  data_row["Gender (Dep #{i+1})"],
        ssn: data_row["SSN (Dep #{i+1})"].to_s.strip.gsub("-","")
        })
    end
  end
  puts "processing #{census_employee.full_name}"

  if census_employee.census_dependents.blank? && census_dependents.present?
    census_employee.census_dependents = census_dependents
    census_employee.save!
  end

  benefit_begin_date = format_date(data_row["Benefit Begin Date"])

  plan_year = organization.employer_profile.plan_years.published_plan_years_by_date(benefit_begin_date).first
  plan_year = organization.employer_profile.plan_years.detect{|py| (py.start_on..py.end_on).cover?(benefit_begin_date)} if plan_year.blank?

  if plan_year.blank?
    row["Error Message"] = "No plan year Found to cover this enrollment"
    next
  end

  begin
    correct_benefit_group = plan_year.benefit_groups.detect{|bg| data_row["Benefit Package/Benefit Group"].strip.downcase == bg.title.strip.downcase }
    benefit_group_assignment = select_benefit_group_assignment(data_row["Benefit Package/Benefit Group"], census_employee)
  rescue Exception=>e
    row["Error Message"] = e.inspect
    complete_rows.push(row)
    next
  end

  if benefit_group_assignment.blank?
    benefit_group_assignment = census_employee.benefit_group_assignments.new(benefit_group: correct_benefit_group, start_on: benefit_begin_date)
    benefit_group_assignment.save!
    benefit_group_assignment.make_active
  end


  subscriber = Person.where(hbx_id: data_row['HBX ID']).first
  employee_role = subscriber.employee_roles.where(:employer_profile_id => organization.employer_profile.id).first if subscriber

    if  employee_role.blank?
      if subscriber.present?
        employee_role = Factories::EnrollmentFactory.build_employee_role(subscriber, false, census_employee.employer_profile, census_employee, census_employee.hired_on).first
      else
      employee_role = Factories::EnrollmentFactory.construct_employee_role(nil,census_employee,person_details).first
    end



    employee_role.benefit_group_id = benefit_group_assignment.benefit_group_id
    employee_role.save!

    subscriber = employee_role.person
    subscriber.hbx_id = data_row["HBX ID"]
    subscriber.save
    end

  ## Add contact info
  unless data_row["Address Kind"].blank?
    subscriber.addresses.build(:kind => data_row["Address Kind"],
                   :address_1 => data_row["Address 1"],
                   :address_2 => data_row["Address 2"],
                   :city => data_row["City"],
                   :state => data_row["State"],
                   :zip => data_row["Zip"].to_s)
    subscriber.save
  end
  unless data_row["Phone Type"].blank?
    subscriber.phones.build(:kind => data_row["Phone Type"],
                :full_phone_number => data_row["Phone Number"].to_s.gsub("(","").gsub(")","").gsub("-",""))
    subscriber.save
  end
  unless data_row["Email Kind"].blank?
    subscriber.emails.build(:kind => data_row["Email Kind"],
                :address => data_row["Email Address"])
    subscriber.save
  end

  family = subscriber.primary_family
  hh = family.active_household
  ch = hh.immediate_family_coverage_household

  6.times do |i|
    next unless data_row["Enrollee End Date (Dep #{i+1})"].blank?
    if data_row["HBX ID (Dep #{i+1})"] != nil
      dependent = find_dependent(data_row["SSN (Dep #{i+1})"].to_s.gsub("-",""), data_row["DOB (Dep #{i+1})"],
        data_row["First Name (Dep #{i+1})"],data_row["Middle Name (Dep #{i+1})"],data_row["Last Name (Dep #{i+1})"])
            if dependent.blank? || dependent.to_s == "dependent does not exist for provided person details"
              begin
              dependent = OpenStruct.new
              dependent.first_name = data_row["First Name (Dep #{i+1})"]
              dependent.middle_name = data_row["Middle Name (Dep #{i+1})"]
              dependent.last_name = data_row["Last Name (Dep #{i+1})"]
              dependent.ssn = data_row["SSN (Dep #{i+1})"].to_s.gsub("-","")
              dependent.dob = format_date(data_row["DOB (Dep #{i+1})"]).strftime("%Y-%m-%d")
              dependent.employee_relationship = census_employee.census_dependents.where(first_name: dependent.first_name,
                                                    middle_name: dependent.middle_name,
                                                    last_name: dependent.last_name,
                                                    dob: dependent.dob).first.employee_relationship
              rescue Exception=>e
                row["Error Message"] = "Cannot find census dependent #{data_row["First Name (Dep #{i+1})"]} #{data_row["Last Name (Dep #{i+1})"]} - #{e.inspect}"
                complete_rows.push(row)
              end
              family_member = Factories::EnrollmentFactory.initialize_dependent(family,subscriber,dependent)
              unless family_member == nil
                begin
                family_member.save
                family_member.person.gender = data_row["Gender (Dep #{i+1})"]
                family_member.person.hbx_id =  data_row["HBX ID (Dep #{i+1})"]
                rescue Exception=>e
                  row["Error Message"] = "#{e.inspect}"
                  complete_rows.push(row)
                end

                begin
                  family_member.person.save
                  ch_member = ch.add_coverage_household_member(family_member)
                  ch_member.save
                  ch.save
                  family.save
                rescue Exception=>e
                  row["Error Message"] = "#{e.inspect}"
                  complete_rows.push(row)
                end
              end
            else
              family_member = family.family_members.detect{|fm| fm.hbx_id == dependent.hbx_id}
              ch_member = ch.coverage_household_members.detect{|ch_member| ch_member.family_member_id == family_member._id}
              if ch_member.blank?
                ch_member = ch.add_coverage_household_member(family_member)
              end
            end
    end
  end

  start_date = format_date(data_row["Benefit Begin Date"])
  plan = Plan.where(hios_id: data_row["HIOS ID"], active_year: data_row["Plan Year"].strip).first

  if plan.blank?
    raise " Unable to find plan with HIOS ID #{data_row["HIOS ID"]} for year #{data_row["Plan Year"].strip}"
    row["Error Message"] = "Unable to find plan with HIOS ID #{data_row["HIOS ID"]} for year #{data_row["Plan Year"].strip}"
    complete_rows.push(row)
  end

  en = hh.new_hbx_enrollment_from({
    coverage_household: ch,
    employee_role: employee_role,
    benefit_group: benefit_group_assignment.benefit_group,
    benefit_group_assignment: benefit_group_assignment
    })
  en.effective_on = start_date
  en.hbx_enrollment_members.each do |mem|
    mem.eligibility_date = start_date
    mem.coverage_start_on = start_date
  end

  en.carrier_profile_id = plan.carrier_profile_id
  en.plan_id = plan.id
  en.aasm_state =  "coverage_selected"
  en.coverage_kind = 'health'
  en.hbx_id = data_row["Enrollment Group ID"]

  en.save!

  true

  row["Error Message"] = "#{en.hbx_id} loaded successfully."
  complete_rows.push(row)

  # rescue Exception=>e
  #   puts e.inspect
  #   binding.pry
  #   puts "-"*100
  #   #puts e.backtrace
  # end
end

CSV.open("#{filename.gsub(".csv","")}_errors.csv","w") do |csv|
  csv << ["Redmine Ticket","Employer Name","Employer FEIN",
      "HBX ID","First Name","Middle Name","Last Name","SSN","DOB","Gender",
      "Address Kind","Address 1","Address 2","City","State","Zip",
      "Phone Type","Phone Number",
      "Email Kind","Email Address",
      "AASM State",
      "Enrollment Group ID","Enrollment Kind","Benefit Begin Date", "Benefit End Date",
      "Plan Year","HIOS ID","Benefit Package/Benefit Group","Date Plan Selected","Relationship",
      "HBX ID (Dep 1)","First Name (Dep 1)","Middle Name (Dep 1)","Last Name (Dep 1)",
      "SSN (Dep 1)","DOB (Dep 1)","Gender (Dep 1)","Relationship (Dep 1)",
      "HBX ID (Dep 2)","First Name (Dep 2)","Middle Name (Dep 2)","Last Name (Dep 2)",
      "SSN (Dep 2)","DOB (Dep 2)","Gender (Dep 2)","Relationship (Dep 2)",
      "HBX ID (Dep 3)","First Name (Dep 3)","Middle Name (Dep 3)","Last Name (Dep 3)",
      "SSN (Dep 3)","DOB (Dep 3)","Gender (Dep 3)","Relationship (Dep 3)",
      "HBX ID (Dep 4)","First Name (Dep 4)","Middle Name (Dep 4)","Last Name (Dep 4)",
      "SSN (Dep 4)","DOB (Dep 4)","Gender (Dep 4)","Relationship (Dep 4)",
      "HBX ID (Dep 5)","First Name (Dep 5)","Middle Name (Dep 5)","Last Name (Dep 5)",
      "SSN (Dep 5)","DOB (Dep 5)","Gender (Dep 5)","Relationship (Dep 5)",
      "HBX ID (Dep 6)","First Name (Dep 6)","Middle Name (Dep 6)","Last Name (Dep 6)",
      "SSN (Dep 6)","DOB (Dep 6)","Gender (Dep 6)","Relationship (Dep 6)"]
  complete_rows.each do |row|
    csv << row
  end
end

