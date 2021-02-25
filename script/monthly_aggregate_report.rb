# frozen_string_literal: true

# rails runner script/monthly_aggregate_report.rb -e production
require 'csv'

field_names = %w[PrimaryFirstName PrimaryLastName PrimaryHbxID EnrollmentHbxId EnrollmentEffectiveOn EnrollmentAppliedAptcAmount EnrollmentAggregateAptcAmount(MonthlyAggreageAmount)]

file_name = "#{Rails.root}/storage_of_enr_effective_date_and_monthly_aggregate_amount_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names
  current_date = TimeKeeper.date_of_record
  hbx_enrollments = HbxEnrollment.individual_market.by_health.where(
          :effective_on => (current_date.beginning_of_year)..(current_date.end_of_year),
          :aasm_state.in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES,
          :"applied_aptc_amount.cents".gt => 0,
          :"aggregate_aptc_amount.cents".gt => 0)
  hbx_enrollments.each do |enrollment|
    primary_person = enrollment.family.primary_person
    csv << [primary_person.first_name,
            primary_person.last_name,
            primary_person.hbx_id,
            enrollment.hbx_id,
            enrollment.effective_on,
            enrollment.applied_aptc_amount,
            enrollment.aggregate_aptc_amount]
  end
rescue StandardError => e
  puts "Error: #{e.message}"
end
