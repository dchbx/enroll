require File.join(Rails.root, "app", "data_migrations", "change_enrollment_termination_date")
# This rake task is to terminate an enrollment with a given termination date
# RAILS_ENV=production bundle exec rake migrations:change_ce_termination_date ssn="123456789" date_of_termination=12/01/2016
namespace :migrations do
  desc "changing ce_termination date for enrollment"
  ChangeCeTerminationDate.define_task :change_enrollment_termination_date => :environment
end