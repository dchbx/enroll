require 'csv'
include VerificationHelper

@end_date = Date.new(2017, 12, 29)
@start_date = Date.new(2017, 12, 20)

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name)

families = Family.where({
                            "households.hbx_enrollments" => {
                                "$elemMatch" => {
                                    "kind" => "individual",
                                    "submitted_at" => {:"$gte" => @start_date, :"$lte" => @end_date},
                                    "aasm_state" => { "$in" =>  HbxEnrollment::ENROLLED_STATUSES },
                                    "effective_on" => { :"$gte" => Date.new(2017,12,20)}
                                }
                            }
                        })

report_name = "#{Rails.root}/enrollment_effected_people.csv"

total_families = families.count
offset_count = 0
limit_count = 500
processed_count = 0

def valid_person?(person)
  person.consumer_role.special_verifications.where(verification_type: 'Citizenship').present?
end

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while (offset_count <= total_families) do
    families.offset(offset_count).limit(limit_count).each do |family|
      begin
        primary_person = family.primary_applicant.person
        notice_present = primary_person.inbox.messages.where(subject: 'Your Health or Dental Plan Enrollment and Payment Deadline').present?
        if notice_present
          outstanding_exist = false
          family.family_members.map(&:person).each do|person|
            if valid_person?(person)
              outstanding_exist = true
              break
            end
          end
          if outstanding_exist
            csv << [
                primary_person.hbx_id,
                primary_person.first_name,
                primary_person.last_name
            ]
          end
        end
      rescue Exception => e
        puts "Exception #{e.backtrace}" unless Rails.env.test?
      end
    end
    offset_count = offset_count + limit_count
  end
end
