require File.join(Rails.root, "app", "data_migrations", "remove_employer_staff_role_from_person")

# RAILS_ENV=production bundle exec rake migrations:remove_employer_staff_role_from_person person_hbx_id=112777622 employer_staff_role_id="123123123123"

namespace :migrations do
  desc "remove_employer_staff_role_from_person"
  RemoveEmployerStaffRoleFromPerson.define_task :remove_employer_staff_role_from_person => :environment
end
