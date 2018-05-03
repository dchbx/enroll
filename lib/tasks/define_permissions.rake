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

namespace :permissions do
  desc 'hbx admin can complete resident application'
  DefinePermissions.define_task :hbx_admin_can_complete_resident_application => :environment
end

namespace :permissions do
  desc 'hbx admin can add sep'
  DefinePermissions.define_task :hbx_admin_can_add_sep => :environment
end

namespace :permissions do
  desc 'hbx admin can view username and email'
  DefinePermissions.define_task :hbx_admin_can_view_username_and_email => :environment
end

namespace :permissions do
  desc 'hbx admin can transition family members'
  DefinePermissions.define_task :hbx_admin_can_transition_family_members => :environment
end

#rake permissions:initial_hbx
#rake permissions:migrate_hbx
#rake permissions:hbx_admin_can_update_ssn
#rake permissions:hbx_admin_can_complete_resident_application
#rake permissions:hbx_admin_can_transition_family_members
