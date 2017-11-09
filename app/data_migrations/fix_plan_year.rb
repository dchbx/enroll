require File.join(Rails.root, "lib/mongoid_migration_task")

class FixPlanYear < MongoidMigrationTask
  def migrate

    employer_profile = EmployerProfile.find_by_fein(ENV['fein'])

    if employer_profile.present?

      plan_year_start_on = Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y")
      plan_year = employer_profile.plan_years.where(start_on: plan_year_start_on).first
      prev_state = plan_year.aasm_state

      plan_year.end_on = Date.strptime(ENV['end_on'].to_s, "%m/%d/%Y") if ENV['end_on']
      plan_year.aasm_state = ENV['aasm_state']
      plan_year.terminated_on = ENV['terminated_on'].present? ? Date.strptime(ENV['terminated_on'].to_s, "%m/%d/%Y") : " "

      if plan_year.save!
        plan_year.workflow_state_transitions << WorkflowStateTransition.new(from_state: prev_state, to_state: ENV['aasm_state'])
        puts "plan year updated" unless Rails.env.test?

        if plan_year.aasm_state == "active"
          find_by_benefit_groups(plan_year.benefit_groups).each do |enrollment|
            enrollment.update_attributes!(terminated_on: nil, termination_submitted_on: nil, aasm_state: "coverage_selected")
            puts "enrollemnt updated #{enrollment.hbx_id}" unless Rails.env.test?
            enrollment.hbx_enrollment_members.each { |mem| mem.update_attributes!(coverage_end_on: nil)}
          end

        elsif ["canceled","renewing_canceled"].include?("#{plan_year.aasm_state}")
          find_by_benefit_groups(plan_year.benefit_groups).each do |enrollment|
            enrollment.update_attributes(aasm_state: "coverage_canceled")
            puts "enrollemnt updated #{enrollment.hbx_id}" unless Rails.env.test?
          end

        elsif plan_year.aasm_state == "terminated"
          find_by_benefit_groups(plan_year.benefit_groups).each do |enrollment|
            enrollment.update_attributes(aasm_state: "coverage_terminated")
            puts "enrollemnt updated #{enrollment.hbx_id}" unless Rails.env.test?
            enrollment.hbx_enrollment_members.each { |mem| mem.update_attributes!(coverage_end_on: plan_year.end_on)}
          end

        elsif plan_year.aasm_state == "expired"
          find_by_benefit_groups(plan_year.benefit_groups).each do |enrollment|
            enrollment.update_attributes(aasm_state: "coverage_expired")
            puts "enrollemnt updated #{enrollment.hbx_id}" unless Rails.env.test?
          end
        end
      else
        puts "unable to save plan year" unless Rails.env.test?
      end
    else
      puts "employer Profile not found" unless Rails.env.test?
    end

  end

  def find_by_benefit_groups(benefit_groups)
    id_list = benefit_groups.collect(&:_id).uniq
    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).canceled_and_terminated.to_a
    end
  end
end
