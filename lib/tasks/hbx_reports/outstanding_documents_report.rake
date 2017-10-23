require 'rake'
require "#{Rails.root}/lib/documents_verification_status"
require "#{Rails.root}/app/helpers/verification_helper"
include VerificationHelper
# This is a report that is generated for audit purpose, for all families with outstanding documents
# The task to run is RAILS_ENV=production bundle exec rake reports:outstanding_documents_list

namespace :reports do

  desc 'List of outstanding documents of families'
  task outstanding_documents_list: :environment do
    count = 0
    families = Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => 'enrolled_contingent')
    if families.present?
      file_name = "#{Rails.root}/public/outstanding_documents_report_#{TimeKeeper.date_of_record.strftime('%Y-%m-%d')}.csv"
      CSV.open(file_name, 'w', force_quotes: true) do |csv|
        csv << %w[HBX_ID First_Name Last_Name Number_of_Documents Due_Date Review_Color]
        families.each do |family|
          person = family.primary_applicant.person
          document_count = documents_count(family)
          min_verification_due_date = family.min_verification_due_date || TimeKeeper.date_of_record + 95.days
          status = review_button_class(family)
          color = color_scheme(status)
          csv << [person.hbx_id,
                  person.first_name,
                  person.last_name,
                  document_count,
                  min_verification_due_date,
                  color]
          count += 1
        end
        puts "File path: %s. Total count of families with outstanding documents: #{count}"
      end
    else
      puts 'Families with outstanding documents does not exist.. Quitting Rake Task!!'
    end
  end

  def color_scheme(status)
    if status == 'success'
      'green'
    elsif status == 'info'
      'blue'
    else
      'white'
    end
  end

end
