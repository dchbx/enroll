require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeNewHireRule < MongoidMigrationTask
  def migrate
     organization = Organization.where(fein: ENV['fein']).first
     benefit_groups = organization.employer_profile.plan_years.last.benefit_groups
     benefit_groups.each do |benefit_group|
       benefit_group.effective_on_kind = "first_of_month" if benefit_group.effective_on_kind == "date_of_hire"
       benefit_group.save
     end
  end
end
