# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ExpireOldContingentEnrollments < MongoidMigrationTask
  def update_enrollment(enrollment)
    enrollment.assign_attributes(aasm_state: "coverage_expired", is_any_enrollment_member_outstanding: true)
    enrollment.workflow_state_transitions << WorkflowStateTransition.new(from_state: "enrolled_contingent",
                                                                         to_state: "coverage_expired", comment: "Expired inactive enrollments from previous year via data migration")
    enrollment.save!
  end

  def migrate
    start_of_year = TimeKeeper.date_of_record.beginning_of_year
    families = Family.by_enrollment_individual_market.where(
      :_id.in => HbxEnrollment.where(
        aasm_state: "enrolled_contingent",
        effective_on: {:"$lte" => TimeKeeper.date_of_record.end_of_year}
      ).pluck(:family_id)
    )
    families.each do |family|

      contingent_enrollments = family.active_household.hbx_enrollments.where(aasm_state: "enrolled_contingent", :effective_on.lte => start_of_year)
      if contingent_enrollments.present?
        contingent_enrollments.each { |enrollment| update_enrollment(enrollment) }
        puts "Successfully transitioned enrollments for family with family_id: #{family.id}" unless Rails.env.test?
      end
    rescue StandardError => e
      puts "Could not transition enrollments for family with family_id: #{family.id}, Error: #{e.backtrace}" unless Rails.env.test?

    end
  end
end