
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePlanYearEffectiveDate < MongoidMigrationTask
  def migrate
    begin
      organizations = Organization.where(fein: ENV['fein'])
      state = ENV['aasm_state'].to_s
      start_on = Date.strptime((ENV['py_new_start_on']).to_s, "%m/%d/%Y")
      hios_id = ENV['referenece_plan_hios_id']
      ref_plan_active_year = ENV['ref_plan_active_year']
      if organizations.size !=1
        raise 'Issues with fein'
      end
      open_enrollment_start_on = (start_on - 30.days).beginning_of_month
      plan_year = organizations.first.employer_profile.plan_years.where(aasm_state: state).first
      plan_year.update_attributes(start_on: start_on, end_on: start_on + 1.year - 1.day, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_start_on + 13.days)
      puts "Changing Plan Year effective on to #{start_on}" unless Rails.env.test?
      if hios_id.present? && ref_plan_active_year.present?
        plan_year.benefit_groups.each do |benefit_group|
          benefit_group.reference_plan = Plan.where(:hios_id => hios_id, active_year: ref_plan_active_year).first
          benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
          puts "Changed reference plan id " unless Rails.env.test?
        end
      end
      if plan_year.save!
        Rake::Task["migrations:correct_invalid_benefit_group_assignments_for_employer"].invoke unless Rails.env.test?
        puts "Plan Year Saved!!" unless Rails.env.test?
        plan_year.force_publish! if plan_year.may_force_publish?
      else
        puts "#{plan_year.errors.full_messages}" unless Rails.env.test?
      end
    rescue
      puts "Incorrect environment variables"
    end
  end
end
