## Pass the date range as given below to generate cobra report
## rails r script/qle_new_hire_report.rb "11/01/2017" "12/10/2017"

require 'csv'

@start_date = Date.strptime(ARGV[0], "%m/%d/%Y").beginning_of_day
@end_date  = Date.strptime(ARGV[1], "%m/%d/%Y").end_of_day

@carriers = CarrierProfile.all.inject({}){|data, c| data[c.id.to_s] = c.legal_name; data }


def enrollment_reason(enrollment)
  if enrollment.is_special_enrollment?
    enrollment.special_enrollment_period.title
  else
    "New Hire"
  end
end

def sep_or_newhire_date(enrollment)
  if enrollment.is_special_enrollment?
    enrollment.special_enrollment_period.qle_on.strftime("%m/%d/%Y")
  else
    enrollment.benefit_group_assignment.census_employee.hired_on.strftime("%m/%d/%Y")
  end
end

def get_plan_details(enrollment, employer)
  plan = enrollment.plan
  data = [
    employer.legal_name,
    employer.fein,
    enrollment.benefit_group.start_on.strftime("%m/%d/%Y"),
    enrollment.hbx_id,
    enrollment.time_of_purchase.strftime("%m/%d/%Y"),
    enrollment.effective_on.strftime("%m/%d/%Y"),
    enrollment.coverage_kind,
    enrollment.aasm_state.titleize,
    enrollment.total_premium,
    enrollment.total_employer_contribution,
    plan.name,
    plan.hios_id,
    @carriers[plan.carrier_profile_id.to_s],
    plan.plan_type,
    plan.metal_level,
    enrollment_reason(enrollment),
    sep_or_newhire_date(enrollment)
  ]
end

def get_member_details(enrollment_member, enrollment)
  person = enrollment_member.person
  relationship = enrollment_member.primary_relationship || 'self'

  [
    person.hbx_id,
    person.ssn,
    person.dob.strftime('%m/%d/%Y'),
    person.gender, nil,
    person.first_name,
    person.middle_name,
    person.last_name,
    person.mailing_address.try(:zip),
    relationship,
    enrollment.premium_for(enrollment_member)
  ]
end

def header_rows
  data = [
    "Employer Name",
    "Employer FEIN",
    "Employer Plan Year Begin",
    "Enrollment Group ID",
    "Plan Selected On",
    "Benefit Begin Date",
    "Coverage Kind",
    "Enrollment Status",
    "Total Premium",
    "Employer Contribution",
    "Plan HIOS ID",
    "Plan Name",
    "Carrier Name",
    "Plan Type (HMS/PPO/etc.)",
    "Plan metal level",
    "New Hire/SEP",
    "New Hire/SEP (Date)",
    "Subscriber HBX ID",
    "Subscriber SSN",
    "Subscriber DOB",
    "Subscriber Gender",
    "Subscriber Premium",
    "Subscriber First Name",
    "Subscriber Middle Name",
    "Subscriber Last Name",
    "Subscriber Zip",
    "SELF (only one option)",
    "Subscriber Premium"
  ]

  8.times{ |i|
    data += [
      "Dep#{i+1} HBX ID",
      "Dep#{i+1} SSN",
      "Dep#{i+1} DOB",
      "Dep#{i+1} Gender ",
      "Dep#{i+1} Premium",
      "Dep#{i+1} First Name ",
      "Dep#{i+1} Middle Name",
      "Dep#{i+1} Last Name",
      "Dep#{i+1} Zip",
      "Dep#{i+1} Relationship",
      "Dep#{i+1} Premium"
    ]
  }

  data
end

def sep_query_expression
  {
    :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES),
    :created_at.gte => @start_date,
    :created_at.lte => @end_date,
    :kind.in => %w(employer_sponsored employer_sponsored_cobra),
    :enrollment_kind => "special_enrollment",
    :coverage_kind.in => %w(health dental)
  }
end


def newhire_query_expression
  {
    :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES + ["auto_renewing"]),
    :created_at.gte => @start_date,
    :created_at.lte => @end_date,
    :kind.in => %w(employer_sponsored employer_sponsored_cobra),
    :enrollment_kind => "open_enrollment",
    :coverage_kind.in => %w(health dental)
  }
end


CSV.open("#{Rails.root.to_s}/sep_newhire_enrollment_report.csv", "w") do |csv|
  csv << header_rows
  count = 0

  families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => sep_query_expression})
  puts "Found #{families.size} families in the system"

  families.each do |family|
    count += 1
    if count % 100 == 0
      puts "process #{count}"
    end

    active_enrollments = family.active_household.hbx_enrollments.where(sep_query_expression)
    next if active_enrollments.blank?

    active_enrollments.each do |enrollment|
      employer = enrollment.benefit_group.plan_year.employer_profile

      begin
        data = get_plan_details(enrollment, employer)

        next if enrollment.hbx_enrollment_members.blank?

        primary_member = enrollment.hbx_enrollment_members.detect{|member| member == enrollment.subscriber }
        primary_member = enrollment.hbx_enrollment_members.first if primary_member.blank?


        data += get_member_details(primary_member, enrollment)

        enrollment.hbx_enrollment_members.each do |enrollment_member|
          if enrollment_member == primary_member
            data
          else
            data += get_member_details(enrollment_member, enrollment)
          end
        end

        csv << data
      rescue Exception => e
        puts "bad enrollment #{e.to_s} #{enrollment.hbx_id}"
      end
    end
  end

  families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => newhire_query_expression})
  puts "Found #{families.size} families in the system"

  families.each do |family|
    count += 1
    if count % 100 == 0
      puts "process #{count}"
    end

    active_enrollments = family.active_household.hbx_enrollments.where(newhire_query_expression)
    next if active_enrollments.blank?

    active_enrollments.each do |enrollment|
      employer = enrollment.benefit_group.plan_year.employer_profile
      next unless enrollment.benefit_group_assignment.census_employee.new_hire_enrollment_period.cover?(enrollment.created_at)

      begin
        data = get_plan_details(enrollment, employer)

        next if enrollment.hbx_enrollment_members.blank?

        primary_member = enrollment.hbx_enrollment_members.detect{|member| member == enrollment.subscriber }
        primary_member = enrollment.hbx_enrollment_members.first if primary_member.blank?


        data += get_member_details(primary_member, enrollment)

        enrollment.hbx_enrollment_members.each do |enrollment_member|
          if enrollment_member == primary_member
            data
          else
            data += get_member_details(enrollment_member, enrollment)
          end
        end

        csv << data
      rescue Exception => e
        puts "bad enrollment #{e.to_s} #{enrollment.hbx_id}"
      end
    end
  end
end
