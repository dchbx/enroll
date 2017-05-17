require File.join(Rails.root, "app", "data_migrations", "remove_dependent_from_ee_enrollment")
# This rake task is to remove invalid benefit group assignment under census employee
# RAILS_ENV=production bundle exec rake migrations:remove_dependent_from_ee_enrollment enrollment_id=523277 enrollment_member_id=5724e267082e7610fb0099e1
namespace :migrations do
  desc "remove dependent from ee enrollment"
  RemoveDependentFromEeEnrollment.define_task :remove_dependent_from_ee_enrollment => :environment
end
