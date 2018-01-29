require File.join(Rails.root, "app", "data_migrations", "correct_employees_with_incorrect_waivers")

# RAILS_ENV=production bundle exec rake migrations:correct_employees_with_incorrect_waivers year=2017

namespace :migrations do
  desc "Cancel waivers from employees accounts who actively bought coverage, also passively renew employees who got incorrect renewal waivers"
  CorrectEmployeesWithIncorrectWaivers.define_task :correct_employees_with_incorrect_waivers => :environment
end
