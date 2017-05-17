require File.join(Rails.root, "app", "data_migrations", "expire_conversion_employers")
# This rake task is for cancellation of enrollments from csv file using enrollment hbx ids
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_effective_on_date filename="xyz.csv"

namespace :migrations do
  desc "Expire non converting conversion ERs"
  ExpireConversionEmployers.define_task :expire_conversion_employers => :environment
end
