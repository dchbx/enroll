# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class InvalidateHbxEnrollmentWithBrokenCurrentPremium < MongoidMigrationTask
  # By running invalidate_enrollment, enrollments won't appear under the scope
  # of the families#home page
  def migrate
    person_hbx_id = ENV['person_hbx_id'].to_s
    @person = Person.where(hbx_id: person_hbx_id).first
    @family = @person.primary_family
    @hbx_enrollments = @family.hbx_enrollments
    unless Rails.env.test?
      abort("Aborted! Unable to find person with hbx_id #{@person_hbx_id}.") if @person.blank?
      abort("Aborted! No family record found for person with hbx_id #{@person_hbx_id}.") if @family.blank?
      abort("Aborted! Unable to find person with hbx_id #{@person_hbx_id}.") if @hbx_enrollments.blank?
    end
    invalidate_enrollments if @hbx_enrollments.present?
  end

  # Mimics families_helper.rb#current_premium
  def valid_current_premium?(hbx_enrollment)
    if hbx_enrollment.is_shop?
      hbx_enrollment.total_employee_cost
      true
    elsif hbx_enrollment.kind == 'coverall'
      hbx_enrollment.total_premium
      true
    else
      hbx_enrollment.total_premium > hbx_enrollment.applied_aptc_amount.to_f ? hbx_enrollment.total_premium - hbx_enrollment.applied_aptc_amount.to_f : 0
      true
    end
  rescue Exception => e
    exception_message = "Current Premium calculation error for HBX Enrollment: #{hbx_enrollment.hbx_id}"
    Rails.logger.error(exception_message) unless Rails.env.test?
    puts(exception_message) unless Rails.env.test?
    false
  end

  def invalidate_enrollments
    unable_to_validate_enrollments = []
    @hbx_enrollments.each do |hbx_enrollment|
      unless valid_current_premium?(hbx_enrollment)
        if HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES.exclude?(hbx_enrollment.aasm_state)
          hbx_enrollment.invalidate_enrollment!
          puts("Invaliding enrollment with hbx_id #{hbx_enrollment.hbx_id}") unless Rails.env.test?
        else
          unable_to_validate_enrollments << hbx_enrollment
          puts("Unable to invalidate enrollment with hbx_id #{hbx_enrollment.hbx_id}") unless Rails.env.test?
        end
      end
    end
    if unable_to_validate_enrollments.present? && !Rails.env.test?
      puts("Unable to invalidate the following active enrollments:")
      unable_to_validate_enrollments.map { |hbx_enrollment| puts(hbx_enrollment.hbx_id.to_s) }
      puts("Please calculate their total premiums and update their records appropriately.")
    end
  end
end
