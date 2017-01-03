def create_directory(path)
  if Dir.exists?(path)
    FileUtils.rm_rf(path)
  end
  Dir.mkdir path
end

families = Family.where({
  "households.hbx_enrollments" => {
    "$elemMatch" => {
      "aasm_state" => { "$in" => ["enrolled_contingent"] },
      "effective_on" => { "$gte" => Date.new(2016,1,1)},
      "submitted_at" => { "$gt" => Date.new(2016,7,22)},
  } }
}).to_a

mailing_address_missing = []
coverage_not_found = []
pending_ssa_validation = []
others = []

create_directory "#{Rails.root.to_s}/public/paper_notices/"

CSV.open("families_processed_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w") do |csv|

  csv << [
    'Family Id',
    'Family ECase ID',
    'Person name', 
    'Hbx ID'
  ]

  count   = 0
  counter = 0

  families.each do |family|

    next if family.active_household.hbx_enrollments.where(:"special_verification_period".lt => Date.new(2016,10,26)).present?
    counter += 1
    begin
      person = family.primary_applicant.person

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
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver

      csv << [family.id, family.e_case_id, person.full_name, person.hbx_id]

      puts 'processed--' + person.full_name

    rescue Exception  => e
      case e.to_s 
      when 'needs ssa validation!'
        pending_ssa_validation << person.full_name
      when 'mailing address not present'
        mailing_address_missing << person.full_name
      when 'active coverage not found!'
        coverage_not_found << person.full_name
      else 
        puts "#{family.e_case_id}----#{e.to_s}"
      end
    end

    if counter % 200 == 0
      puts "processed #{counter} families"
    end
  end

  if count > 0
    puts "#{count} families skipped due to missing consumer role"
  end

  puts pending_ssa_validation.count 
  puts mailing_address_missing.count
  puts coverage_not_found.count
  puts others.count
end