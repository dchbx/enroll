
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePlanYearEffectiveDate < MongoidMigrationTask
  def migrate
    begin
      organizations = Organization.where(fein: ENV['fein'])
      state = ENV['aasm_state'].to_s
      start_on = Date.strptime((ENV['py_new_start_on']).to_s, "%m/%d/%Y")
      hios_id = ENV['referenece_plan_hios_id']
      ref_plan_active_year = ENV['ref_plan_active_year']
      action_on_enrollments = ENV['action_on_enrollments']
      plan_year_state = ENV['plan_year_state']

      if organizations.size !=1
        raise 'Issues with fein'
      end

      def all_enrollments(benefit_groups=[])
        id_list = benefit_groups.collect(&:_id).uniq

        families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
        families.inject([]) do |enrollments, family|
          enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).to_a
        end
      end

      plan_year = organizations.first.employer_profile.plan_years.where(aasm_state: state).first
      enrollments = all_enrollments(plan_year.benefit_groups)

      if plan_year.may_revert_renewal? && plan_year_state == "revert_renewal"
        enrollments.each { |enr| enr.cancel_coverage! if enr.may_cancel_coverage? }
        puts "cancelling all enrollments under renewing plan year" unless Rails.env.test?
        plan_year.revert_renewal!
        puts "reverting renewing plan year" unless Rails.env.test?
      end

      if plan_year.may_revert_application? && plan_year_state == "revert_application"
        enrollments.each { |enr| enr.cancel_coverage! if enr.may_cancel_coverage? }
        puts "cancelling all enrollments under active plan year" unless Rails.env.test?
        plan_year.revert_application!
        puts "reverting active plan year" unless Rails.env.test?
      end

      if !(organizations.first.employer_profile.is_conversion?) || organizations.first.employer_profile.renewing_published_plan_year.present?
        puts "Renewing plan year for the conversion employer is published (Or) Employer is not a conversion Employer. You cannot perform this action." unless Rails.env.test?
        return
      end
      open_enrollment_start_on = start_on.last_month.beginning_of_month
      open_enrollment_end_on = PlanYear::RENEWING.include?(plan_year.aasm_state) ? open_enrollment_start_on + 12.days : open_enrollment_start_on + 9.days
      plan_year.update_attributes(start_on: start_on, end_on: start_on + 1.year - 1.day, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on)
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
        plan_year.force_publish! if plan_year.may_force_publish? && plan_year_state == "force_publish"
      else
        puts "#{plan_year.errors.full_messages}" unless Rails.env.test?
      end

      bg_list = plan_year.benefit_groups.pluck(:id)
      families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => bg_list)
      enrollments = families.inject([]) do |enrollments, family|
                      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => bg_list)
                    end

      def invalid_enrollment?(enrollment, plan_year)
        enrollment.effective_on < plan_year.start_on
      end

      enrollments.each do |enrollment|
        begin
          if invalid_enrollment?(enrollment, plan_year)
            enrollment.update_attributes!(effective_on: plan_year.start_on)
            puts "updated enrollment effective_on date for HbxEnrollment: #{enrollment.hbx_id}" unless Rails.env.test?
          end
        rescue => e
          puts "Enrollment: #{enrollment.hbx_id} Exception: #{e}"
        end
      end

      if action_on_enrollments == "py_start_on" # when the ask was to change all the enrollments effective on to py start on

        def invalid_enrollment?(enrollment, plan_year)
          enrollment.effective_on != plan_year.start_on
        end

        enrollments.each do |enrollment|
          begin
            if invalid_enrollment?(enrollment, plan_year)
              enrollment.update_attributes!(effective_on: plan_year.start_on)
              puts "updated enrollment effective_on date for HbxEnrollment: #{enrollment.hbx_id}" unless Rails.env.test?
            end
          rescue => e
            puts "Enrollment: #{enrollment.hbx_id} Exception: #{e}"
          end
        end
      end

    rescue Exception => e
      puts e.message
    end
  end
end
