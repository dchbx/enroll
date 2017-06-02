# Rake task to terminate enrollment with a given date
# To run rake task: RAILS_ENV=production bundle exec rake migrations:terminate_enr_with_date enr_hbx_id="210100" termination_date="7/1/2016"

require File.join(Rails.root, "app", "data_migrations", "terminate_enr_with_date")
namespace :migrations do
  desc "Terminate enrollment with a given date"
  TerminateEnrWithDate.define_task :terminate_enr_with_date => :environment
end
