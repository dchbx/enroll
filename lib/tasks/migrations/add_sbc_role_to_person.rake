require File.join(Rails.root, "app", "data_migrations", "add_sbc_role_to_person")
# This rake task is to create sbc role to a person
# RAILS_ENV=production bundle exec rake migrations:add_sbc_role_to_person hbx_id=1234,5678

namespace :migrations do
  desc "create sbc role to a person"
  AddSbcRoleToPerson.define_task :add_sbc_role_to_person => :environment
end
