
require File.join(Rails.root, "lib/mongoid_migration_task")

class MigratePlanYear < MongoidMigrationTask
  def migrate
    feins=ENV['feins'].split(' ').uniq
    feins.each do |fein|
      organizations = Organization.where(fein: fein)
      next puts "unable to find employer_profile with fein: #{fein}" if organizations.blank?
      if organizations.size > 1
        raise 'more than 1 employer found with given fein'
      end
      organizations.each do |organization|
        plan_years = organization.employer_profile.plan_years
        plan_years.each do |plan_year|
        plan_year.conversion_expire! if plan_year.may_conversion_expire?
        end
      end
    end
  end
end
