# Rake task to change Gender of an Employee
# To run rake task: RAILS_ENV=production bundle exec rake migrations:change_gender id="5640343869702d1adf002500" hbx_id="19748191" gender="female"

require File.join(Rails.root, "app", "data_migrations", "change_gender")
namespace :migrations do
  desc "Changing Gender for an Employee"
  ChangeGender.define_task :change_gender => :environment
end
