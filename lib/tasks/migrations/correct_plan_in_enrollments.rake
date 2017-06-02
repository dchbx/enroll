require File.join(Rails.root, "app", "data_migrations", "correct_plan_in_enrollment")
# There are enrollments with plan from the previous year. This task will assign the correct plan.
# RAILS_ENV=production bundle exec rake migrations:correct_plan_in_enrollment
namespace :migrations do
  desc "Some enrollments have plan from the wrong year. This task will fix this."
  CorrectPlanInEnrollment.define_task :correct_plan_in_enrollment => :environment
end