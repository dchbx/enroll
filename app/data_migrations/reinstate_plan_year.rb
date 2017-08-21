require File.join(Rails.root, "lib/mongoid_migration_task")

class ReinstatePlanYear < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")

    if organizations.size != 1
      puts "Found No (or) more than 1 organization with the given fein" unless Rails.env.test?
      return
    end

    plan_year = organizations.first.employer_profile.plan_years.where(start_on: plan_year_start_on).first
    if plan_year.present? && plan_year.may_reinstate_plan_year?
      plan_year.reinstate_plan_year!
      puts "Plan Year Reinstated" unless Rails.env.test?
    else
      puts "Unable to reinstate plan year/Plan Year not found." unless Rails.env.test?
    end
  end
end
