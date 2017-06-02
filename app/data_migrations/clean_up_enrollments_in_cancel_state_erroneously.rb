require File.join(Rails.root, "lib/mongoid_migration_task")
# Expected Outcome:
# 1. Enrollments should be changed from the Terminated to Canceled.
# 2. Coverage end date for affected enrollments should be equal to the enrollment effective date.
# 3. Provide an output identifying the following: Primary Subscriber HBX ID, E1 HBX ID, E1 effective date, E1 Market type, E2 HBX ID
class CleanUpEnrollmentsInCancelStateErroneously < MongoidMigrationTask
  def migrate
    puts "Primary Subscriber HBX ID, Enrollment HBX ID, Effective Date, Market Type, Enrollment 2 HBX ID" unless Rails.env.test?

    families=Family.where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::TERMINATED_STATUSES)

      families.each do |family|
        enrollments = family.active_household.hbx_enrollments

        family.active_household.hbx_enrollments.where(aasm_state:"coverage_terminated").each do |terminated_enrollment|
          enrollments.each do |enrollment|
            if terminated_enrollment.kind == enrollment.kind
              terminate_member = terminated_enrollment.hbx_enrollment_members.where(is_subscriber:true).first
              active_member = enrollment.hbx_enrollment_members.where(is_subscriber:true).first
              if terminate_member.present? && active_member.present?
                if terminate_member.id == active_member.id
                  terminate_effective = terminated_enrollment.effective_on
                  active_effective = enrollment.effective_on
                  terminated_submitted = terminated_enrollment.submitted_at
                  active_submitted = enrollment.submitted_at
                  #Proposed Conditions for data:
                  #1. X effective date = Y effective date.
                  if terminate_effective == active_effective
                    if terminate_effective.present? && active_submitted.present?
                      #2. E1 effective date > E2 submitted on date.
                      if terminate_effective > active_submitted.to_date
                        # Expected Outcome:
                        # 1. Enrollments should be changed from the Terminated to Canceled.
                         terminated_enrollment.update(aasm_state:'coverage_expired')
                        # 2. Coverage end date for affected enrollments should be equal to the enrollment effective date.
                         terminated_enrollment.update(terminated_on:active_effective)
                        # 3. Provide an output identifying the following: Primary Subscriber HBX ID, E1 HBX ID, E1 effective date, E1 Market type, E2 HBX ID
                        puts "#{active_member.person.hbx_id}, #{terminated_enrollment.hbx_id}, #{terminate_effective}, #{terminated_enrollment.kind}, #{enrollment.hbx_id}" unless Rails.env.test?
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
  end
end
