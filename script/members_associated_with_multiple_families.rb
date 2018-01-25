require 'csv'

def get_employer_details(enrollment)
  employer = enrollment.benefit_group.employer_profile
  census_employee = enrollment.benefit_group_assignment.census_employee

  broker_agency = employer.active_broker_agency_account
  broker = Person.where("broker_role._id" => BSON::ObjectId.from_string(broker_agency.writing_agent_id)).first if broker_agency

  [
    employer.legal_name,
    employer.fein,
    broker.try(:full_name),
    broker.try(:broker_role).try(:npn),
    census_employee.hired_on.strftime("%m/%d/%Y")
  ]
end

def get_plan_details(enrollment)
  plan = enrollment.plan
  [
    enrollment.effective_on.strftime("%m/%d/%Y"),
    plan.try(:name),
    nil, nil, nil,
    plan.try(:hios_id),
    nil, nil, nil,
    enrollment.aasm_state.titleize
  ]
end

def get_member_details(person, relationship = 'self')
  [
   person.ssn,
   person.dob.strftime('%m/%d/%Y'),
   person.gender, nil,
   person.first_name,
   person.middle_name,
   person.last_name,
   person.work_email_or_best,
   person.work_phone_or_best,
   person.mailing_address.try(:address_1),
   person.mailing_address.try(:address_2),
   person.mailing_address.try(:city),
   person.mailing_address.try(:state),
   person.mailing_address.try(:zip),
   relationship
  ]
end

def header_rows
  data = [
    "Duplicate SSN",
    "Market",
    "Sponsor Name",
    "FEIN",
    "Broker Name",
    "Broker NPN",
    "Hire Date ",
    "Benefit Begin Date",
    "Plan Name",
    "QHP Id (ignore) ",
    "CSR Info (ignore) ",
    "CSR Variant (ignore)",
    "HIOS Id (AUTO) ",
    "Premium Total",
    "Employer Contribution (AUTO)",
    "Employee Responsible Amt",
    "Enrollment Status",
    "Subscriber SSN",
    "Subscriber DOB",
    "Subscriber Gender",
    "Subscriber Premium",
    "Subscriber First Name",
    "Subscriber Middle Name",
    "Subscriber Last Name",
    "Subscriber Email",
    "Subscriber Phone",
    "Subscriber Address 1",
    "Subscriber Address 2",
    "Subscriber City",
    "Subscriber State",
    "Subscriber Zip",
    "SELF (only one option)"
  ]

  8.times{ |i|
    data += [
      "Dep#{i+1} SSN",
      "Dep#{i+1} DOB",
      "Dep#{i+1} Gender ",
      "Dep#{i+1} Premium",
      "Dep#{i+1} First Name ",
      "Dep#{i+1} Middle Name",
      "Dep#{i+1} Last Name",
      "Dep#{i+1} Email",
      "Dep#{i+1} Phone",
      "Dep#{i+1} Address 1",
      "Dep#{i+1} Address 2",
      "Dep#{i+1} City ",
      "Dep#{i+1} State",
      "Dep#{i+1} Zip",
      "Dep#{i+1} Relationship"
    ]
  }

  data
end


CSV.open("#{Rails.root.to_s}/dependents_present_on_multiple_families.csv", "w") do |csv|
  csv << header_rows

  count = 0

  re = Regexp.union(/^12345/,/^000/,/^999/,/^123/,/^98765/,/^012345/,/^987/)

  Person.all.each do |person|

    next if person.families.size < 2
    next if !(person.ssn.present? && person.ssn.match(re))


    # families = person.families.select do |f| 
    #   begin
    #     f.primary_applicant.person.employee_roles.any? 
    #   rescue Exception => e
    #     puts "bad family record #{f.e_case_id} #{f.id}"
    #   end
    # end
    # next if families.empty?

    families = person.families.select{|family|
      family_member_ids = family.family_members.select{|fm| fm.person_id == person.id}.map(&:id)
      enrollments = family.active_household.hbx_enrollments.where({:"hbx_enrollment_members.applicant_id".in => family_member_ids, :"hbx_enrollment.aasm_state".ne => 'shopping' })
      enrollments.any?
    }

    next if families.size < 2

    families.each do |family|
      family_member_ids = family.family_members.collect{|fm| fm.id if fm.person_id == person.id}.uniq
      enrollments = family.active_household.hbx_enrollments.where({:"hbx_enrollment_members.applicant_id".in => family_member_ids, :"hbx_enrollment.aasm_state".ne => 'shopping' })

      enrollments.each do |enrollment|

        begin
          data  = [person.ssn, enrollment.kind.titleize]
          if enrollment.kind == "employer_sponsored"
            data += get_employer_details(enrollment)
          else
            data += 5.times.collect{nil}
          end
          data += get_plan_details(enrollment)
          data += get_member_details(family.primary_applicant.person)

          enrollment.hbx_enrollment_members.each do |enrollment_member|
            data += get_member_details(enrollment_member.person, enrollment_member.primary_relationship)
          end

          csv << data
        rescue Exception => e
          puts "bad enrollment #{e.to_s} #{enrollment.hbx_id}"
        end
      end
    end

    count += 1
  end
end