#rails runner script/count_for_ivl_paper_notices_december.rb

start_at, end_at = Date.new(2017, 12, 01).to_date, Date.new(2017, 12, 31).to_date

final_eligibility_notice_count = 0
enr_notice_count = 0
final_renewal_notice_count = 0
first_reminder_notice_count = 0

final_enr_subject = "Your Final Eligibility Results, Plan, And Option To Change Plans"
enr_notice_subject = "Your Health or Dental Plan Enrollment and Payment Deadline"
final_renewal_notice_subject = "Review Your Insurance Plan Enrollment and Pay Your Bill Now"
first_reminder_notice_subject = "Reminder - You Must Submit Documents by the Deadline to Keep Your Insurance"

Person.all_consumer_roles.by_message_created_at_datetime_range(start_at, end_at).each do |person|
  begin
    if person.consumer_role.can_receive_paper_communication?
      messages = person.inbox.messages.by_created_at_date_range(start_at, end_at)

      if messages.map(&:subject).include?(final_enr_subject)
        final_eligibility_notice_count += messages.by_created_at_date_range(start_at, end_at).where(subject: final_enr_subject).count
      end

      if messages.map(&:subject).include?(enr_notice_subject)
        enr_notice_count += messages.by_created_at_date_range(start_at, end_at).where(subject: enr_notice_subject).count
      end

      if messages.map(&:subject).include?(final_renewal_notice_subject)
        final_renewal_notice_count += messages.by_created_at_date_range(start_at, end_at).where(subject: final_renewal_notice_subject).count
      end

      if messages.map(&:subject).include?(first_reminder_notice_count)
        first_reminder_notice_count += messages.by_created_at_date_range(start_at, end_at).where(subject: first_reminder_notice_count).count
      end
    end
  rescue => e
    puts e unless Rails.env.test?
  end
end

puts "Total_final_eligibility_notice_count: #{final_eligibility_notice_count}, Total_enrollment_notice_count: #{enr_notice_count}, Total_final_renewal_notice_count: #{final_renewal_notice_count}, Total_first_reminder_notice_count: #{first_reminder_notice_count}" unless Rails.env.test?
