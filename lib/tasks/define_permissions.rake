require File.join(Rails.root, "app", "data_migrations", "define_permissions")

#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'

namespace :permissions do
  desc 'define the permissions'
  DefinePermissions.define_task :initial_hbx => :environment
end
namespace :permissions do
  desc 'build test roles'
  DefinePermissions.define_task :build_test_roles => :environment
end
namespace :permissions do
  desc 'hbx admin can update ssn'
  DefinePermissions.define_task :hbx_admin_can_update_ssn => :environment
end

#rake permissions:initial_hbx
#rake permissions:migrate_hbx
#rake permissions:hbx_admin_can_update_ssn