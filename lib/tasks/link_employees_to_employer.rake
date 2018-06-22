# Rake tasks used to update the aasm_state of the employer to enrolled && plan year aasm state to enrolled.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:link_employees_to_employer ce=57644137f1244e0adf000011,57644137f1244e0adf000005
require File.join(Rails.root, "app", "data_migrations", "link_employees_to_employer")

namespace :migrations do
  desc "Link employees to employer"
  LinkEmployeesToEmployer.define_task :link_employees_to_employer => :environment
end