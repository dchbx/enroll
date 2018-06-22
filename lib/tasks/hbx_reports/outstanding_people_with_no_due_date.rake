require 'rake'
require "#{Rails.root}/app/helpers/verification_helper"
include VerificationHelper

# The task to run is RAILS_ENV=production bundle exec rake reports:outstanding_people_with_no_due_date

namespace :reports do

  desc 'List of outstanding families with no due date'
  task outstanding_people_with_no_due_date: :environment do
    count = 0
    families = Family.outstanding_verification.where(min_verification_due_date: nil)
    if families.present?
      file_name = "#{Rails.root}/public/outstanding_people_with_no_due_date_#{TimeKeeper.date_of_record.strftime('%Y-%m-%d')}.csv"
      CSV.open(file_name, 'w', force_quotes: true) do |csv|
        csv << %w[HBX_ID First_Name Last_Name Due_Date DC_Residency Citizenship Social_Security_Number American_Indian/Alaskan_Native Immigration_Status]
        families.each do |family|
          next if family.has_valid_e_case_id?
          primary_family_member = family.primary_family_member
          person = primary_family_member.person
          min_verification_due_date = family.min_verification_due_date.present? ? family.min_verification_due_date : (TimeKeeper.date_of_record+ 95.days).strftime('%Y-%m-%d')
          outstanding_doc_types(family, primary_family_member)
          csv << [person.hbx_id,
                  person.first_name,
                  person.last_name,
                  min_verification_due_date,
                  @residency_doc_type,
                  @citizenship_doc_type,
                  @ssn_doc_type,
                  @ami_doc_type,
                  @immigration_doc_type]
          count += 1
        end
          puts "File path: %s. Total count of families with outstanding no due date: #{count}"
      end
    else
      puts 'Families with outstanding documents does not exist.. Quitting Rake Task!!'
    end
  end

  def outstanding_doc_types(family, family_member)
    @citizenship_doc_type = @ssn_doc_type = @ami_doc_type = @immigration_doc_type = @residency_doc_type = 'N'
    family_member.person.consumer_role.outstanding_verification_types.each do |v_type|
      case v_type
        when 'DC Residency'
          @residency_doc_type = 'Y'
        when 'Citizenship'
          @citizenship_doc_type = 'Y'
        when 'Social Security Number'
          @ssn_doc_type = 'Y'
        when 'American Indian Status'
          @ami_doc_type= 'Y'
        when 'Immigration status'
          @immigration_doc_type = 'Y'
      end
    end
  end

end
