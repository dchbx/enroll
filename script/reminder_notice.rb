
outstanding_people_ids = Person.where(
    "consumer_role" => {"$exists" => true, "$ne" => nil},
    "consumer_role.aasm_state" => "verification_outstanding").map(&:_id)

families = Family.where("family_members.person_id" => {"$in" => outstanding_people_ids})

file_name = "#{Rails.root}/reminder_notice_list#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

def check_inbox_message(person, subject)
  person.inbox.present? && person.inbox.messages.where(:"subject" => subject).present?
end


CSV.open(file_name, "w") do |csv|
  csv << [
    'Family Id',
    'Person name', 
    'Hbx ID',
    'Notice Type'
  ]
  families.each do |fam|
    begin
      person = fam.primary_applicant.person
      cr = person.consumer_role

      initial_notice_date = cr.workflow_state_transitions.detect{ |t| t.to_state == "verification_outstanding"}.try(:transition_at).to_date

      reminder_days = (DateTime.now.to_date).mjd - initial_notice_date.mjd

      if fam.enrollments.order(created_at: :desc).select{|e| e.currently_active? || e.future_active?}.present?
        case reminder_days
        when 10
          binding.pry
          if check_inbox_message(person,"Documents needed to confirm eligibility for your plan")
            VerificationReminderNotice.perform_later(cr.id.to_s, "first_verifications_reminder")
            csv << [fam.id, person.full_name, person.hbx_id, "First Reminder Notice"]
          end
        when 25
          if check_inbox_message(person,"Request for Additional Information - First Reminder")
            VerificationReminderNotice.perform_later(cr.id.to_s, "second_verifications_reminder")
            csv << [fam.id, person.full_name, person.hbx_id, "Second Reminder Notice"]
          end
        when 50
          if check_inbox_message(person,"Request for Additional Information - Second Reminder")
            VerificationReminderNotice.perform_later(cr.id.to_s, "third_verifications_reminder")
            csv << [fam.id, person.full_name, person.hbx_id, "Third Reminder Notice"]
          end
        when 65
          if check_inbox_message(person,"Request for Additional Information - Third Reminder")
            VerificationReminderNotice.perform_later(cr.id.to_s, "fourth_verifications_reminder")
            csv << [fam.id, person.full_name, person.hbx_id, "Fourth Reminder Notice"]
          end
        end
      end

    rescue Exception => e
      case e.to_s
      when 'needs ssa validation!'
        pending_ssa_validation << person.full_name
      when 'mailing address not present'
        mailing_address_missing << person.full_name
      when 'active coverage not found!'
        coverage_not_found << person.full_name
      else
        puts "#{fam.e_case_id}----#{e.to_s} #{e.backtrace}"
      end
    end
  end
  # puts pending_ssa_validation.count
  # puts mailing_address_missing.count
  # puts coverage_not_found.count
  # puts others.count
end