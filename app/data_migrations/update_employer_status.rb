require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateEmployerStatus< MongoidMigrationTask

  def migrate
    begin
      organization = Organization.where(fein: ENV['fein']).first
      if organization.present?
        if organization.employer_profile.may_force_enroll?
          organization.employer_profile.force_enroll!
          puts "successfully updated the aasm_state of #{organization.employer_profile.legal_name} to #{organization.employer_profile.aasm_state}" unless Rails.env.test?
          return unless ENV['plan_year_start_on'].present?
          plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
          plan_year = organization.employer_profile.plan_years.where(:start_on => plan_year_start_on).first
          if plan_year.present?
            plan_year.update_attribute(:aasm_state,'enrolled')
            puts "successfully updated the aasm_state of plan year to #{plan_year.aasm_state}" unless Rails.env.test?
          end
        end
      else
        puts "No organization was found by the given fein" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
