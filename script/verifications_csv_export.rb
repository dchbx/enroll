families = Family.where({
  "households.hbx_enrollments" => {
   "$elemMatch" => {
    # "aasm_state" => {
    #   "$in" => ["enrolled_contingent", "unverified"]
    #   },
      "kind" => { "$ne" => "employer_sponsored" },
      "$or" => [
        {:terminated_on => nil },
        {:terminated_on.gt => TimeKeeper.date_of_record}
      ]
    }  
  }
})


# people_ids = Person.where("consumer_role.aasm_state" => /out/i, "consumer_role.lawful_presence_determination.vlp_authority" => {"$ne" => "curam"}).map(&:id)
# families = Family.where("family_members.person_id" => {"$in" => people_ids})

# families = [127825,19764117,19771408].map{|hbx_id| Person.where(:hbx_id => hbx_id).first}.map(&:primary_family)

mailing_address_missing = []
coverage_not_found = []
pending_ssa_validation = []
docs_uploaded = []

CSV.open("verifications_backlog_notice_data_export_1.csv", "w") do |csv|

  csv << [
    'Primary HbxId',
    'Primary Firstname', 
    'Primary Lastname',
    'Address',
    'Verification Due Date', 
    'Enrollment Submitted On', 
    'Coverage Start Date', 
    'SSN Unverified', 
    'Citizenship/Immigration Unverified',
    'Communication Preference',
    'EMail'
  ]

  count   = 0
  counter = 0

  families.each do |family|
    counter += 1

    next if ["564d098469702d174fa10000", "565197e569702d6e52dd0000"].include?(family.id.to_s)

    begin

    person = family.primary_applicant.person
    #  if (person.inbox.present? && person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").present?)
    #   puts "already notified!!"
    #   next
    # end

    next if person.inbox.blank?
    next if person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").blank?
    if secure_message = person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").first
      next if secure_message.created_at > 35.days.ago
    end

    if person.consumer_role.blank?
      count += 1
      next
    end

      event_kind = ApplicationEventKind.where(:event_name => 'verifications_backlog').first
      notice_trigger = event_kind.notice_triggers.first 

      builder = notice_trigger.notice_builder.camelize.constantize.new(person.consumer_role, {
        template: notice_trigger.notice_template, 
        subject: event_kind.title, 
        mpi_indicator: notice_trigger.mpi_indicator
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences))

      builder.build
      csv << builder.to_csv 

    rescue Exception  => e
      case e.to_s 
      when 'needs ssa validation!'
        pending_ssa_validation << person.full_name
      when 'mailing address not present'
        puts "#{person.hbx_id.inspect}"
        mailing_address_missing << person.full_name
      when 'active coverage not found!'
        coverage_not_found << person.full_name
      when 'documents already uploaded'
        docs_uploaded << person.full_name
      else
        puts e.to_s.inspect
      end
    end

    if counter % 200 == 0
      puts "processed #{counter} families"
    end
  end

  puts "#{count} families skipped due to missing consumer role"

  puts pending_ssa_validation.count 
  puts mailing_address_missing.count
  puts coverage_not_found.count
  puts docs_uploaded.inspect
  puts docs_uploaded.count
end