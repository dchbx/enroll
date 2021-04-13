# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateEnrollmentWithAptc < MongoidMigrationTask
  def migrate
    enrollments = HbxEnrollment.by_hbx_id(ENV['enrollment_hbx_id'].to_s)
    if enrollments.count != 1
      puts "found more than one/no enrollment with hbx_id #{ENV['enrollment_hbx_id']}" unless Rails.env.test?
      return
    end
    enrollment = enrollments.first
    new_effective_date = Date.strptime(ENV['new_effective_date'], "%m/%d/%Y")
    applied_aptc_amount = ENV['applied_aptc_amount'].to_f

    reinstatement = reinstate(enrollment, new_effective_date, applied_aptc_amount)
    update_enrollment_members_aptc(reinstatement, applied_aptc_amount)
    reinstatement.select_coverage!
    if ENV['terminated_on'].present?
      terminated_on = Date.strptime(ENV['terminated_on'], "%m/%d/%Y")
      reinstatement.terminate_coverage!(terminated_on) if reinstatement.may_terminate_coverage?
    end
  rescue StandardError => e
    puts e.to_s
  end

  def reinstate(enrollment, new_effective_date, applied_aptc_amount)
    replicator = Enrollments::Replicator::Reinstatement.new(enrollment, new_effective_date, applied_aptc_amount).build
    replicator.save!
    replicator
  end

  def update_enrollment_members_aptc(reinstatement, applied_aptc_amount)
    Insured::Factories::SelfServiceFactory.update_enrollment_for_apcts(reinstatement, applied_aptc_amount)
  end
end