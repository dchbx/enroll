# frozen_string_literal: true

# This script generates a report to list all the ivl active
# enrollments in the prior plan years
# rails runner script/active_enrollments_in_prior_years_report.rb -e production
require 'csv'
field_names = %w[First_Name
                 Last_Name
                 HBX_ID
                 Application_Year
                 Health_or_Dental
                 Enrollment_hbx_id
                 Aasm_state]

file_name = "#{Rails.root}/active_enrollments_in_prior_years_list.csv"

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names
  start_date_of_current_year = TimeKeeper.date_of_record.beginning_of_year
  enrollments = HbxEnrollment.all.where(kind: 'individual',
                                        :aasm_state.in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES,
                                        :effective_on.lt => start_date_of_current_year)

  enrollments.each do |enrollment|
    primary_person = enrollment.family.primary_person
    csv << [primary_person.first_name, primary_person.last_name,
            primary_person.hbx_id, enrollment.effective_on.year,
            enrollment.coverage_kind, enrollment.hbx_id,
            enrollment.aasm_state]
  rescue StandardError => e
    puts "Error: #{e.message}" unless Rails.env.test?
  end
end
