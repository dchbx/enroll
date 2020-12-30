# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
class ExpirePriorYearIvlActiveEnrollments < MongoidMigrationTask
  def migrate
    field_names = %w[First_Name
                     Last_Name
                     HBX_ID
                     Application_Year
                     Health_or_Dental
                     Enrollment_hbx_id
                     Aasm_state]

    file_name = "#{Rails.root}/expired_active_enrollments_in_prior_years.csv"

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      start_date_of_current_year = TimeKeeper.date_of_record.beginning_of_year
      enrollments = HbxEnrollment.all.where(kind: 'individual',
                                            :aasm_state.in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES,
                                            :effective_on.lt => start_date_of_current_year)

      enrollments.each do |enrollment|
        enrollment.expire_coverage! if enrollment.may_expire_coverage?
        primary_person = enrollment.family.primary_person
        csv << [primary_person.first_name, primary_person.last_name,
                primary_person.hbx_id, enrollment.effective_on.year,
                enrollment.coverage_kind, enrollment.hbx_id,
                enrollment.aasm_state]
      rescue StandardError => e
        puts "Error: #{e.message}" unless Rails.env.test?
      end
    end
  end
end
