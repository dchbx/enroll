# Rake tasks used to update the aasm_state of the employer to enrolled && plan year aasm state to enrolled.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:link_employees_to_employer ce1=57644137f1244e0adf000011 ce2=57644137f1244e0adf000005 ce3=57644137f1244e0adf00000b ce4=57644137f1244e0adf000020 ce5=57644137f1244e0adf000014
require File.join(Rails.root, "app", "data_migrations", "link_employees_to_employer")

namespace :migrations do
  desc "Link employees to employer"
  LinkEmployeesToEmployer.define_task :link_employees_to_employer => :environment
end