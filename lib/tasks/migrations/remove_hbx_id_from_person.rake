require File.join(Rails.root, "app", "data_migrations", "remove_hbx_id_from_person")
# This rake task is to remove a hbx id from a person
# RAILS_ENV=production bundle exec rake migrations:remove_hbx_id p1_id="19767831" p2_id="19899836" hbx="19767832"
namespace :migrations do
  desc "remove_hbx_id_from_person"
  RemoveHbxIdFromPerson.define_task :remove_hbx_id_from_person => :environment
end