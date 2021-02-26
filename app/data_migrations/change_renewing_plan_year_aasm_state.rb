require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeRenewingPlanYearAasmState< MongoidMigrationTask

  def migrate
    begin
      organization = Organization.where(fein: ENV['fein']).first
      if organization.present?
        return unless ENV['plan_year_start_on'].present?
        plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
        aasm_state = ENV['state'].to_s if ENV['state'] == "renewing_enrolled"
        py_aasm_state = ENV['py_aasm_state'].to_s
        plan_year = organization.employer_profile.plan_years.where(:start_on => plan_year_start_on, :aasm_state => py_aasm_state).first
        if plan_year.present?
          plan_year.revert_renewal! if plan_year.may_revert_renewal?
          plan_year.withdraw_pending! if plan_year.renewing_publish_pending?
          plan_year.renew_publish! if plan_year.may_renew_publish?
          plan_year.advance_date! if plan_year.may_advance_date? # renewing_enrolling
          plan_year.advance_date! if plan_year.is_enrollment_valid? && plan_year.is_open_enrollment_closed? && plan_year.may_advance_date? && aasm_state.present? # to renewing_enrolled

          if plan_year.renewing_enrolled? && plan_year.may_activate?  # for late renewal employer plan year already started employer moving plan year to active state.
            employer_enroll_factory = Factories::EmployerEnrollFactory.new
            employer_enroll_factory.date = TimeKeeper.date_of_record
            employer_enroll_factory.employer_profile = organization.employer_profile
            employer_enroll_factory.begin
            if organization.employer_profile.plan_years.where(start_on:plan_year_start_on - 1.year).present?
              expiring_plan_year = organization.employer_profile.plan_years.where(start_on:plan_year_start_on - 1.year).first
              expiring_plan_year.hbx_enrollments.each do |enrollment|
                enrollment.expire_coverage! if enrollment.may_expire_coverage?
                expiring_plan_year.expire! if expiring_plan_year.may_expire?
              end
            end
          end

          puts "Plan year aasm state changed to #{plan_year.aasm_state}" unless Rails.env.test?
        end
      else
        puts "No organization was found by the given fein" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
