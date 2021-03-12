# frozen_string_literal: true

# This script generates a report to list all the Kaiser enrollments
# rails runner script/kaiser_enrollment_list_for_pay_now.rb -e production
require 'csv'
field_names = %w[First_Name
                 Last_Name
                 HBX_ID
                 Application_Year
                 Enrollment_hbx_id
                 Aasm_state]

logger_field_names = %w[Enrollment_ID Backtrace]

report_file_name = "#{Rails.root}/kaiser_enrollment_list_for_pay_now_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
logger_file_name = "#{Rails.root}/kaiser_enrollment_list_for_pay_now_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
  logger_csv << logger_field_names
  CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
    report_csv << field_names
    enrollments = HbxEnrollment.all.where(:kind.in => ['individual', 'coverall'],
                                          :aasm_state.in => ['coverage_selected'],
                                          :effective_on => TimeKeeper.date_of_record,
                                          :product_id.ne => nil,
                                          :coverage_kind.in => ['health'])
    enrollments.each do |enrollment|
      next unless enrollment.product.issuer_profile.legal_name == EnrollRegistry[:pay_now_functionality].setting(:carriers).item
      primary_person = enrollment.family.primary_person
      report_csv << [primary_person.first_name, primary_person.last_name,
              primary_person.hbx_id, enrollment.effective_on.year,
              enrollment.hbx_id, enrollment.aasm_state]
    rescue StandardError => e
      logger_csv << [enrollment.id, e.backtrace[0..5].join('\n')]
    end
  end
end 