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

  desc 'hbx admin can lock and unlock a user'
  DefinePermissions.define_task :hbx_admin_can_lock_unlock => :environment

  desc 'hbx admin can reset password a user'
  DefinePermissions.define_task :hbx_admin_can_reset_password => :environment
end

namespace :permissions do
  desc 'hbx admin can add sep'
  DefinePermissions.define_task :hbx_admin_can_add_sep => :environment
end

namespace :permissions do
  desc 'hbx admin can add pdc'
  DefinePermissions.define_task :hbx_admin_can_add_pdc => :environment
end

namespace :permissions do
  desc 'hbx admin can view username and email'
  DefinePermissions.define_task :hbx_admin_can_view_username_and_email => :environment
end

namespace :permissions do
  desc 'hbx admin can view login history'
  DefinePermissions.define_task :hbx_admin_can_view_login_history => :environment
end

#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_change_fein
namespace :permissions do
  desc 'hbx system admin can change fein'
  DefinePermissions.define_task :hbx_admin_can_change_fein => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_force_publish
namespace :permissions do
  desc 'hbx admin can force publish'
  DefinePermissions.define_task :hbx_admin_can_force_publish => :environment
end

namespace :permissions do
  desc 'hbx admin can send secure message'
  DefinePermissions.define_task :hbx_admin_can_send_secure_message => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_extend_open_enrollment
namespace :permissions do
  desc 'hbx admin can extend open enrollment'
  DefinePermissions.define_task :hbx_admin_can_extend_open_enrollment => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_modify_plan_year
namespace :permissions do
  desc 'hbx admin can update plan years'
  DefinePermissions.define_task :hbx_admin_can_modify_plan_year => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_create_benefit_application
namespace :permissions do
  desc 'hbx admin can create benefit application'
  DefinePermissions.define_task :hbx_admin_can_create_benefit_application => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_manage_qles
namespace :permissions do
  desc 'hbx admin can manage SEP types create, update & updation of ordinal position'
  DefinePermissions.define_task :hbx_admin_can_manage_qles => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_manage_settings
namespace :permissions do
  desc 'Super admin can modify resource registry settings'
  DefinePermissions.define_task :hbx_admin_can_manage_settings => :environment
end

# RAILS_ENV=production bundle exec rake permissions:grant_super_admin_access user_email="<email address1>,<email address2>"
namespace :permissions do
  desc 'grant super admin access for given users'
  DefinePermissions.define_task :grant_super_admin_access => :environment
end

# RAILS_ENV=production bundle exec rake permissions:grant_hbx_tier3_access user_email="<email address1>,<email address2>"
namespace :permissions do
  desc 'grant hbx tier3 access for given users'
  DefinePermissions.define_task :grant_hbx_tier3_access => :environment
end

namespace :permissions do
  desc 'hbx admin can view application types of consumer'
  DefinePermissions.define_task :hbx_admin_can_view_application_types => :environment
end

namespace :permissions do
  desc 'hbx admin and csr view personal information page of consumer'
  DefinePermissions.define_task :hbx_admin_csr_view_personal_info_page => :environment
end

namespace :permissions do
  desc 'hbx admin can view new consumer application link tab'
  DefinePermissions.define_task :hbx_admin_access_new_consumer_application_sub_tab => :environment
end

namespace :permissions do
  desc 'hbx admin and csr view new consumer application link tab'
  DefinePermissions.define_task :hbx_admin_can_access_new_consumer_application_sub_tab => :environment
end

namespace :permissions do
  desc 'hbx admin and csr view identity verification link tab'
  DefinePermissions.define_task :hbx_admin_can_access_identity_verification_sub_tab => :environment
end

namespace :permissions do
  desc 'hbx admin can view outstanding verification link tab'
  DefinePermissions.define_task :hbx_admin_can_access_outstanding_verification_sub_tab => :environment
end

namespace :permissions do
  desc 'hbx admin can access accept reject identity documents'
  DefinePermissions.define_task :hbx_admin_can_access_accept_reject_identity_documents => :environment
end

namespace :permissions do
  desc 'hbx admin and all csr access accept reject paper application documents'
  DefinePermissions.define_task :hbx_admin_can_access_accept_reject_paper_application_documents => :environment
end

namespace :permissions do
  desc 'hbx admin can delete identity and paper application documents'
  DefinePermissions.define_task :hbx_admin_can_delete_identity_application_documents => :environment
end

namespace :permissions do
  desc 'hbx admin can transition family members'
  DefinePermissions.define_task :hbx_admin_can_transition_family_members => :environment
end

namespace :permissions do
  desc 'hbx admin can access user account tab'
  DefinePermissions.define_task :hbx_admin_can_access_user_account_tab => :environment
end

namespace :permissions do
  desc 'hbx_admin_can_access_pay_now'
  DefinePermissions.define_task :hbx_admin_can_access_pay_now => :environment
end

namespace :permissions do
  desc 'assign the most current permissions'
  DefinePermissions.define_task :assign_current_permissions => :environment
end

#rake permissions:hbx_admin_can_reset_password

#rake permissions:hbx_admin_access_new_consumer_application_sub_tab
#rake permissions:hbx_admin_access_identity_verification_sub_tab
#rake permissions:hbx_admin_access_outstanding_verification_sub_tab

#RAILS_ENV=production bundle exec rake permissions:initial_hbx
#RAILS_ENV=production bundle exec rake permissions:migrate_hbx
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_update_ssn
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_complete_resident_application

#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_view_application_types
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_csr_view_personal_info_page
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_access_new_consumer_application_sub_tab
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_access_identity_verification_sub_tab
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_access_outstanding_verification_sub_tab
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_access_accept_reject_identity_documents
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_access_accept_reject_paper_application_documents
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_delete_identity_application_documents
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_modify_plan_year
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_access_user_account_tab
#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_transition_family_members
#rake permissions:hbx_admin_can_add_pdc

#rake permissions:initial_hbx
#rake permissions:migrate_hbx
#rake permissions:hbx_admin_can_update_ssn
#rake permissions:hbx_admin_can_complete_resident_application
#rake permissions:hbx_admin_can_access_pay_now
#bundle exec rake permissions:hbx_admin_can_send_secure_message
