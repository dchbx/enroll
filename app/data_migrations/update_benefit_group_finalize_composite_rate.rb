require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateBenefitGroupFinalizeCompositeRate < MongoidMigrationTask

  def migrate
    begin
      organization = Organization.where(fein: ENV['fein']).first
      if organization.present?
        return unless ENV['plan_year_start_on'].present?
        plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
        plan_year = organization.employer_profile.plan_years.where(:start_on => plan_year_start_on, :aasm_state.in => PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE).first
        if plan_year.present?
          plan_year.benefit_groups.each do |bg|
            bg.finalize_composite_rates
            puts "finalize_composite_rates updated for #{plan_year_start_on} plan year " unless Rails.env.test?
          end
        else
          puts "Plan year not found with given start date #{plan_year_start_on}" unless Rails.env.test?
        end
      else
        puts "No organization was found by the given fein" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
