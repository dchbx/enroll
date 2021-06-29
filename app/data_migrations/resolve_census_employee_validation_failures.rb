# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ResolveCensusEmployeeValidationFailures < MongoidMigrationTask

  def migrate
    Organization.exists(:employer_profile => true).each do |org|
      employer_profile = org.employer_profile
      puts "Processing #{org.legal_name}" unless Rails.env.test?

      count = 0
      employer_profile.census_employees.non_terminated.each do |census_employee|

        count += 1
        puts "processed #{count} census_employees" if count % 10 == 0

        census_employee.benefit_group_assignments.each do |assignment|
          enrollment_with_id_exists = nil
          if assignment.hbx_enrollment_id.present?
            enrollment_with_id_exists = HbxEnrollment.where(id: assignment.hbx_enrollment_id).first
            assignment.hbx_enrollment_id = nil
            assignment.save(:validate => false)
            assignment.reload
          end
          next if assignment.valid? && enrollment_with_id_exists.present?
          puts assignment.errors.messages.to_s + " -- #{census_employee.full_name}" unless Rails.env.test?

          if assignment.errors.messages[:hbx_enrollment].present?
            if assignment.errors.messages[:hbx_enrollment].include?("hbx_enrollment required")
              assignment.hbx_enrollment_id = nil
              assignment.save(:validate => false)

              assignment.update(hbx_enrollment_id: assignment.hbx_enrollment.id) if assignment.hbx_enrollment.present?
            else
              enrollment = assignment.hbx_enrollment
              fix_enrollment_benefit_group_assignments(enrollment)

              if assignment.hbx_enrollment_id.present?
                assignment.hbx_enrollment_id = nil
                assignment.save(:validate => false)
                assignment.reload

                enrollment = assignment.hbx_enrollment
                assignment.update(hbx_enrollment_id: enrollment.id)
              end
            end
          end
        end

        active_plan_year = employer_profile.active_plan_year
        next unless active_plan_year.present?
        bg_ids = active_plan_year.benefit_groups.pluck(:_id)


        census_employee.create_benefit_group_assignment(active_plan_year.benefit_groups) if census_employee.active_benefit_group_assignment.blank?
      end
    end
  end

  def fix_enrollment_benefit_group_assignments(enrollment)
    benefit_group = enrollment.benefit_group
    family = enrollment.family

    # Fix enrollments with mismatching benefit group, benefit group assignment
    family.active_household.hbx_enrollments.shop_market.each do |enrollment|
      next unless enrollment.benefit_group_id != enrollment.benefit_group_assignment.benefit_group_id
      benefit_group = enrollment.benefit_group_assignment.benefit_group
      case enrollment.effective_on
      when benefit_group.start_on..benefit_group.end_on
        enrollment.update(benefit_group_id: benefit_group.id)
      when enrollment.benefit_group.start_on..enrollment.benefit_group.end_on
        employee = enrollment.benefit_group_assignment.census_employee
        new_assignment = employee.benefit_group_assignments.where(:benefit_group_id => enrollment.benefit_group_id).first
        new_assignment = create_new_benefit_group_assignment(employee, benefit_group) if new_assignment.blank?
        enrollment.update(benefit_group_assignment_id: new_assignment.id)
      end

      puts "Updated benefit group assignment for HbxId: #{enrollment.hbx_id}" unless Rails.env.test?
    end
  end

  def create_new_benefit_group_assignment(employee, benefit_group)
    assignment = employee.benefit_group_assignments.build(benefit_group: benefit_group, start_on: benefit_group.start_on)
    assignment.save

    assignment.make_active if (PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE).include?(benefit_group.plan_year.aasm_state)

    assignment
  end
end
