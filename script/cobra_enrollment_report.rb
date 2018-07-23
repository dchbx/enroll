## Pass the date range as given below to generate cobra report
## rails r script/cobra_enrollment_report.rb "11/01/2017" "12/10/2017"

require 'csv'

@start_date = Date.strptime(ARGV[0], "%m/%d/%Y").beginning_of_day
@end_date  = Date.strptime(ARGV[1], "%m/%d/%Y").end_of_day

@issuer_profile = BenefitSponsors::Organizations::Organization.issuer_profiles.all.inject({}){|data, c| data[c.id.to_s] = c.legal_name; data }

def get_plan_details(enrollment, employer)
  product = enrollment.product
  data = [
    employer.legal_name,
    employer.fein,
    enrollment.hbx_id,
    enrollment.time_of_purchase.strftime("%m/%d/%Y"),
    enrollment.effective_on.strftime("%m/%d/%Y"),
    enrollment.coverage_kind,
    enrollment.aasm_state.titleize,
    enrollment.total_premium,
    enrollment.total_employer_contribution,
    product.name,
    product.hios_id,
    @issuer_profile[product.issuer_profile_id.to_s],
    product.health_plan_kind,
    product.metal_level
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
    enrollment.decorated_hbx_enrollment.member_enrollments.find { |enrollment| enrollment.member_id == enrollment_member.id }.product_price.round(2).to_f
  ]
end

def header_rows
  data = [
    "Employer Name",
    "Employer FEIN",
    "Enrollment Group ID",
    "Plan Selected On",
    "Benefit Begin Date",
    "Coverage Kind",
    "Enrollment Status",
    "Total Premium",
    "Employer Contribution",
    "Plan Name",
    "Plan HIOS ID",
    "Carrier Name",
    "Plan Type (HMS/PPO/etc.)",
    "Plan metal level",
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

def query_expression
  {
    :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES + ["auto_renewing"]),
    :created_at.gte => @start_date,
    :created_at.lte => @end_date,
    :kind => 'employer_sponsored_cobra',
    :coverage_kind.in => %w(health dental)
  }
end


families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => query_expression})
puts "Found #{families.size} families in the system"

CSV.open("#{Rails.root.to_s}/cobra_enrollment_report.csv", "w") do |csv|
  csv << header_rows
  count = 0

  families.each do |family|

    count += 1
    if count % 100 == 0
      puts "process #{count}"
    end

    active_enrollments = family.active_household.hbx_enrollments.where(query_expression)
    next if active_enrollments.blank?

    
    active_enrollments.each do |enrollment|
      employer = enrollment.benefit_sponsor

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