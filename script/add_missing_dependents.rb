def find_dependent(ssn,dob,first_name,middle_name,last_name)
  unless ssn.blank?
    person = Person.where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)).first
  end

  if person == nil
    person = Person.where(first_name: first_name.to_s.strip, last_name: last_name.to_s.strip, dob: format_date(dob)).first
  else
    return person
  end

  if person == nil
    return ArgumentError.new("dependent does not exist for provided person details")
  else
    return person
  end
end

def format_date(date)
  date = Date.strptime(date,'%m/%d/%Y')
end

filename = '8905_dependents_not_migrated.csv'

complete_rows = []

CSV.foreach(filename, headers: :true) do |row|
  hbx_enrollment = HbxEnrollment.by_hbx_id(row["Enrollment Group ID"]).first


  hbx_enrollment_member_ids = []
  hbx_enrollment.hbx_enrollment_members.each do |hbx_em|
    hbx_enrollment_member_ids.push(hbx_em.person.hbx_id)
  end
  subscriber = hbx_enrollment.subscriber.person
  family = subscriber.primary_family
  household = family.active_household
  ch = household.immediate_family_coverage_household
  census_employee = hbx_enrollment.employee_role.census_employee
  census_dependents = []
  6.times do |i|
    if row["HBX ID (Dep #{i+1})"].present?
      census_dependents << CensusDependent.new({
        first_name: row["First Name (Dep #{i+1})"],
        middle_name: row["Middle Name (Dep #{i+1})"],
        last_name: row["Last Name (Dep #{i+1})"],
        dob: format_date(row["DOB (Dep #{i+1})"]),
        employee_relationship: row["Relationship (Dep #{i+1})"].strip == 'child' ? 'child_under_26' : row["Relationship (Dep #{i+1})"].strip,
        gender:  row["Gender (Dep #{i+1})"],
        ssn: row["SSN (Dep #{i+1})"].to_s.strip.gsub("-","")
        })
    end
  end
  6.times do |i|

    if row["HBX ID (Dep #{i+1})"] != nil
      dependent = find_dependent(row["SSN (Dep #{i+1})"].to_s.gsub("-",""), row["DOB (Dep #{i+1})"], row["First Name (Dep #{i+1})"],row["Middle Name (Dep #{i+1})"],row["Last Name (Dep #{i+1})"])

      family_member = nil
      if dependent.blank? || dependent.to_s == "dependent does not exist for provided person details"
        begin
          dependent = OpenStruct.new
          dependent.first_name = row["First Name (Dep #{i+1})"]
          dependent.middle_name = row["Middle Name (Dep #{i+1})"]
          dependent.last_name = row["Last Name (Dep #{i+1})"]
          dependent.ssn = row["SSN (Dep #{i+1})"].to_s.gsub("-","")
          dependent.dob = format_date(row["DOB (Dep #{i+1})"]).strftime("%Y-%m-%d")
          dependent.employee_relationship = census_employee.census_dependents.where(first_name: dependent.first_name,
           middle_name: dependent.middle_name,
           last_name: dependent.last_name,
           dob: dependent.dob).first.employee_relationship

          family_member = Factories::EnrollmentFactory.initialize_dependent(family,subscriber,dependent)
          subscriber.save!
          family_member.save!


        rescue Exception=>e
          row["Error Message"] = "Cannot find census dependent #{row["First Name (Dep #{i+1})"]} #{row["Last Name (Dep #{i+1})"]} - #{e.inspect}"
          complete_rows.push(row)
        end
      else
        family_member = family.family_members.detect{|fm| fm.hbx_id == dependent.hbx_id}

        if family_member.blank?
          family_member = family.add_family_member(dependent)
        end
      end

      # family_member.person.gender = row["Gender (Dep #{i+1})"]
      # family_member.person.hbx_id =  row["HBX ID (Dep #{i+1})"]
      # family_member.person.save

      family.active_household.add_household_coverage_member(family_member)
      family.save(:validate => false)

      if !hbx_enrollment_member_ids.include?(family_member.person.hbx_id)
        hbx_enrollment.hbx_enrollment_members.push(HbxEnrollmentMember.new({
          applicant_id: family_member.id,
          eligibility_date: hbx_enrollment.subscriber.eligibility_date,
          coverage_start_on: hbx_enrollment.subscriber.coverage_start_on,
        }))

        hbx_enrollment.save
      end
    end
  end
end
