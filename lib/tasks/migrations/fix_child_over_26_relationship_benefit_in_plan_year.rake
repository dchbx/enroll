require File.join(Rails.root, "app", "data_migrations", "fix_invalid_relationship_benefit_in_plan_year")
# This rake task is to fix child_over_26 relationship benefit in plan year.
# RAILS_ENV=production bundle exec rake migrations:set_child_over_26_relationship_false_in_plan_year
namespace :migrations do
  desc "set child_over_26 benefit_relationship to false in plan year"
  FixInvalidRelationshipBenefitInPlanYear.define_task :set_child_over_26_relationship_false_in_plan_year => :environment
end