def create_directory(path)
  if Dir.exists?(path)
    FileUtils.rm_rf(path)
  end
  Dir.mkdir path
end

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

# 19744754, 19745447
# families = [18941570].map{|hbx_id| Person.where(:hbx_id => hbx_id).first}.map(&:primary_family)

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
    counter += 1

    # next unless family.id.to_s == "5619ca5554726532e58b2201"
    next if ["564d098469702d174fa10000", "565197e569702d6e52dd0000"].include?(family.id.to_s)


    begin
      person = family.primary_applicant.person

    # if person.inbox.present? && person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").present?
    #   puts "already notified!!"
    #   next
    # end

    if person.consumer_role.blank?
      count += 1
      next
    end

    next if person.inbox.blank?
    next if person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").blank?
    if secure_message = person.inbox.messages.where(:"subject" => "Documents needed to confirm eligibility for your plan").first
      next if secure_message.created_at > 35.days.ago
    end

      event_kind = ApplicationEventKind.where(:event_name => 'second_verifications_reminder').first
      # event_kind = ApplicationEventKind.where(:event_name => 'verifications_backlog').first

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