require File.join(Rails.root, "app", "data_migrations", "change_date_of_hire")
# This rake task is to change the date of hire for employee role
# RAILS_ENV=production bundle exec rake migrations:change_date_of_hire hbx_ids="87676546,6879809" employer_profile_id="5456787654" new_doh="MM/DD/YYYY"
namespace :migrations do
  desc "change employee role date of hire"
  ChangeDateOfHire.define_task :change_date_of_hire => :environment
end