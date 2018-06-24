require 'csv'
include VerificationHelper

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name)


families = Family.where({
                            "households.hbx_enrollments" => {
                                "$elemMatch" => {
                                    "kind" => "individual",
                                    "aasm_state" => { "$in" =>  HbxEnrollment::ENROLLED_STATUSES },
                                    "effective_on" => { :"$gte" => Date.new(2017,12,19)}
                                }
                            }
                        })

report_name = "#{Rails.root}/enrollment_effected_people.csv"

total_families = families.count
offset_count = 0
limit_count = 500
processed_count = 0

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while (offset_count <= total_families) do
    families.offset(offset_count).limit(limit_count).each do |family|
      begin
        primary_person = family.primary_applicant.person
        notice_present = primary_person.inbox.messages.where(subject: 'Reminder - You Must Submit Documents by the Deadline to Keep Your Insurance').present?
        if notice_present
          outstanding_exist = false
          family.family_members.map(&:person).each do|person|
            if person.consumer_role.special_verifications.where(verification_type: 'Citizenship').present? && !person.consumer_role.lawful_presence_verified?
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
        puts "Unable to deliver to family with PrimaryPerson: #{person.hbx_id} due to the following error #{e.backtrace}" unless Rails.env.test?
      end
    end
    offset_count = offset_count + limit_count
  end
end