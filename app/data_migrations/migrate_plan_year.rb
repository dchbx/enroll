
require File.join(Rails.root, "lib/mongoid_migration_task")

class MigratePlanYear < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size > 1
      raise 'more than 1 employer found with given fein'
    end
    organizations.each do |organization|
      plan_years = organization.employer_profile.plan_years
      plan_years.each do |plan_year|
      plan_year.migration_expire! if plan_year.may_migration_expire?
      end
    end
  end
end
