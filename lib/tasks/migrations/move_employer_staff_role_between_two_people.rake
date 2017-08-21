require File.join(Rails.root, "app", "data_migrations", "move_employer_staff_role_between_two_people")
# This rake task is to move employer_staff_role between two accounts
# RAILS_ENV=production bundle exec rake migrations:move_employer_staff_role_between_two_people from_hbx_id=19778757  to_hbx_id=19778757

namespace :migrations do
  desc "move employer_staff_role_between_two_people"
  MoveEmployerStaffRoleBetweenTwoPeople.define_task :move_employer_staff_role_between_two_people => :environment
end