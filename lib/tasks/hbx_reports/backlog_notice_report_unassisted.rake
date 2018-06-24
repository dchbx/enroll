require 'rake'

# The task to run is RAILS_ENV=production bundle exec rake reports:backlog_notice_data_set

namespace :reports do

  desc 'List of families who will receive backlog notice'
  task backlog_notice_data_set: :environment do
    count = 0
    families = Family.outstanding_verification.where(min_verification_due_date: nil)
    if families.present?
      file_name = "#{Rails.root}/ivl_backlog_notice_uqhp_data_set_#{TimeKeeper.date_of_record.strftime('%Y-%m-%d')}.csv"
      CSV.open(file_name, 'w', force_quotes: true) do |csv|
        csv << %w[ic_number subscriber_id member_id first_Name last_Name document_due_date dependent]
        families.each do |family|
          next if family.has_valid_e_case_id?
          enrollments = family.enrollments.where(:aasm_state => "enrolled_contingent", :effective_on => { :"$gte" => TimeKeeper.date_of_record.beginning_of_year, :"$lte" =>  TimeKeeper.date_of_record.end_of_year }, :kind => "individual")
          family_members = enrollments.inject([]) do |family_members, enrollment|
            family_members += enrollment.hbx_enrollment_members.map(&:family_member)
          end.uniq
          family_members.each do |family_member|
          primary_family_member = family.primary_family_member
          person = family_member.person
          min_verification_due_date = family.min_verification_due_date.present? ? family.min_verification_due_date : (TimeKeeper.date_of_record+ 95.days).strftime('%m/%d/%y')
          csv << [family.id,
                  person.hbx_id,
                  person.hbx_id,
                  person.first_name,
                  person.last_name,
                  min_verification_due_date,
                  family_member == primary_family_member ? 'NO' : 'YES'
          ]
          end
          count += 1
        end
        puts "File path: %s. Total count of families who will receive notice: #{count}"
      end
    else
      puts 'Families does not exist.. Quitting Rake Task!!'
    end
  end
end
