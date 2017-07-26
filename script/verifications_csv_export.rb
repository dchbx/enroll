NOTICE_GENERATOR = ARGV[0]
REMINDER_NOTICE_TRIGGERS = ["verifications_backlog", "first_verifications_reminder", "second_verifications_reminder", "third_verifications_reminder", "fourth_verifications_reminder"]

unless ARGV[0].present? && REMINDER_NOTICE_TRIGGERS.include?(NOTICE_GENERATOR)
  puts "Please enter event a valid name - Event Names: #{REMINDER_NOTICE_TRIGGERS.join(", ")}."
  exit
end

families = Family.where({
  "households.hbx_enrollments" => {
    "$elemMatch" => {
      "aasm_state" => { "$in" => ["enrolled_contingent"] },
      "effective_on" => { "$gte" => Date.new(2017,1,1)},
  } }
}).to_a

mailing_address_missing = []
coverage_not_found = []
pending_ssa_validation = []
docs_uploaded = []

CSV.open("verifications_backlog_notice_data_export_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w") do |csv|

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
    # Excluding the families that doesn't have active 2017 policy in glue
    next if ["5619ca3e54726532e5f7f800", "58a47aae082e7654050000fe", "5845a2fff1244e5da300003d", "58365eab082e76791a000023", "5619c9e954726532e51f6500", "58815e10faca1438a00000ac", "57b5d7c6082e760ae800001e", "584ed433082e76642c000009", "5850661950526c57f2000181", "5850b2bcfaca143098000064", "58514ee4082e7608f800000a", "5852d73ff1244e6ab600014b", "58533536082e764eef00004d", "58534160faca146eb400007f", "5854639250526c4ead0000a9", "58582ce9f1244e65da000013", "58588541f1244e5007000090", "58595c1cf1244e3b3e00000a", "586265edf1244e477600003d", "586be0c0f1244e688500000e", "586becae082e76726900003e", "586d0bb5faca141565000028", "587398d3f1244e71d000000b", "587d666a50526c43a1000010", "5888e2abfaca1439520000d3", "588a3418082e763e6e0000d0", "588f73b550526c34be0001b2", "5890ba8d50526c34b400041a", "5890c1d450526c34d60004db", "5890f01350526c3cb6000085", "58910e43f1244e5565000862", "58911265f1244e5565000875", "58911964082e76600600070b", "58911ad0faca147f14000163", "58912d21faca147ed8000167", "58912db8082e765fbe000844", "58916797f1244e53ae00002a", "589a303650526c1d10000052", "589ccc2cfaca1410090000e9", "58b60709f1244e53c7000073", "57f0852ffaca14480c02689a", "5853146cfaca140a55000037", "586db97e50526c3cca000188", "587ee19dfaca14254f000082", "5888d97ff1244e28270000b7", "588a4cc1082e763e5900013f", "588ba91e082e763f46000102", "58cad138082e765bf600002c"].include?(family.id.to_s)
    next if family.active_household.hbx_enrollments.where(:"special_verification_period".lte => Date.new(2017,03,20)).present?

    begin

      person = family.primary_applicant.person
    # Additional checks for the next round of notices
    #  if (person.inbox.present? && person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").present?)
    #   puts "already notified!!"
    #   next
    # end

      next if person.inbox.blank?
      next if person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").blank?
    # if secure_message = person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").first
    #   next if secure_message.created_at > 35.days.ago
    # end

      if person.consumer_role.blank?
        count += 1
        next
      end

      event_kind = ApplicationEventKind.where(:event_name => NOTICE_GENERATOR).first

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