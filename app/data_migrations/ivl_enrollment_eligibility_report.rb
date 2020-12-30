# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
class IvlEnrollmentEligibilityReport < MongoidMigrationTask

  # Use same criteria as final_eligibility_notice_report_unassisted
  def is_dc_resident(person)
    return person.no_dc_address_reason.present? if person.no_dc_address
    return false if person.addresses.blank?
    address_to_use = person.addresses.map(&:kind).flatten.compact.include?('home') ? 'home' : 'mailing'
    person.addresses.where(kind: address_to_use, state: 'DC').present?
  end

  # Checks if any applied_aptc_amount is applied on enrollment or if the product is a CSR product
  def enrollment_type(enrollment)
    enrollment.applied_aptc_amount.cents > 0 || ['02', '03', '04', '05', '06'].include?(enrollment.product.csr_variant_id)
  end

  def process_enrollments(hbx_enrollments, file_name, offset_count)
    field_names = %w[HBX_ID IC_Number First_Name Last_Name
                     DOB Residency_Status Citizenship_Status
                     Incarceration Enrollment_Type]
    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      hbx_enrollments.no_timeout.limit(5_000).offset(offset_count).inject([]) do |_dummy, enrollment|
        family = enrollment.family
        e_case_id = family.has_valid_e_case_id? ? family.e_case_id.split('#').last : 'N/A'
        enr_type = enrollment_type(enrollment) ? 'AQHP' : 'UQHP'

        enrollment.hbx_enrollment_members.each do |member|
          person = member.person
          resident = is_dc_resident(person) ? 'YES' : 'NO'
          incarcerated = person.is_incarcerated ? 'YES' : 'NO'
          csv << [person.hbx_id, e_case_id, person.first_name,
                  person.last_name, person.dob, resident,
                  person.citizen_status, incarcerated, enr_type]
        end
      rescue StandardError => e
        puts e.message unless Rails.env.test?
      end
    end
  end

  def migrate
    return if TimeKeeper.date_of_record.day != 1

    start_time = DateTime.current
    puts "IvlEnrollmentEligibilityReport start_time: #{start_time}" unless Rails.env.test?
    hbx_enrollments = HbxEnrollment.all.where(kind: 'individual', :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES)
    total_count = hbx_enrollments.count
    enrs_per_iteration = 5_000.0
    number_of_iterations = (total_count / enrs_per_iteration).ceil
    counter = 0

    while counter < number_of_iterations
      file_name = "#{Rails.root}/list_of_ivl_enrolled_members_#{counter + 1}.csv"
      offset_count = enrs_per_iteration * counter
      process_enrollments(hbx_enrollments, file_name, offset_count)
      counter += 1
    end
    end_time = DateTime.current
    puts "IvlEnrollmentEligibilityReport end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}" unless Rails.env.test?
  end
end
