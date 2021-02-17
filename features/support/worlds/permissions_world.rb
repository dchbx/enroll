# frozen_string_literal: true

module PermissionsWorld
  def define_permissions
    Permission.create!(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                       send_broker_agency_message: true, approve_broker: true, approve_ga: true, can_update_ssn: false, can_complete_resident_application: false,
                       can_add_sep: false, can_lock_unlock: true, can_view_username_and_email: false, can_reset_password: false, modify_admin_tabs: true,
                       view_admin_tabs: true, view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission.create!(name: 'hbx_read_only', modify_family: true, modify_employer: false, revert_application: false, list_enrollments: true,
                       send_broker_agency_message: false, approve_broker: false, approve_ga: false,
                       modify_admin_tabs: false, view_admin_tabs: true,  view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission.create!(name: 'hbx_csr_supervisor', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                       send_broker_agency_message: false, approve_broker: false, approve_ga: false,
                       modify_admin_tabs: false, view_admin_tabs: false,  view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission.create!(name: 'hbx_csr_tier2', modify_family: true, modify_employer: true, revert_application: false, list_enrollments: false,
                       send_broker_agency_message: false, approve_broker: false, approve_ga: false,
                       modify_admin_tabs: false, view_admin_tabs: false,  view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission.create!(name: 'hbx_csr_tier1', modify_family: true, modify_employer: false, revert_application: false, list_enrollments: false,
                       send_broker_agency_message: false, approve_broker: false, approve_ga: false,
                       modify_admin_tabs: false, view_admin_tabs: false,  view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission.create!(name: 'developer', modify_family: false, modify_employer: false, revert_application: false, list_enrollments: true,
                       send_broker_agency_message: false, approve_broker: false, approve_ga: false,
                       modify_admin_tabs: false, view_admin_tabs: true,  view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission.create!(name: 'hbx_tier3', modify_family: true, modify_employer: false, revert_application: false, list_enrollments: true,
                       send_broker_agency_message: false, approve_broker: false, approve_ga: false,
                       modify_admin_tabs: false, view_admin_tabs: true,  view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission.create!(name: 'super_admin', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                       send_broker_agency_message: true, approve_broker: true, approve_ga: true, can_update_ssn: false, can_complete_resident_application: false,
                       can_add_sep: false, can_lock_unlock: true, can_view_username_and_email: false, can_reset_password: false, modify_admin_tabs: true,
                       view_admin_tabs: true, can_extend_open_enrollment: true, can_change_fein: true, view_the_configuration_tab: true, can_submit_time_travel_request: false, can_send_secure_message: true)
  end

  def hbx_admin_can_update_ssn
    Permission.super_admin.update_attributes!(can_update_ssn: true)
    Permission.hbx_tier3.update_attributes!(can_update_ssn: true)
    Permission.hbx_staff.update_attributes!(can_update_ssn: true)
  end

  def hbx_admin_can_complete_resident_application
    Permission.hbx_staff.update_attributes!(can_complete_resident_application: true)
    Permission.super_admin.update_attributes!(can_complete_resident_application: true)
    Permission.hbx_tier3.update_attributes!(can_complete_resident_application: true)
  end

  def hbx_admin_can_add_sep
    Permission.hbx_staff.update_attributes!(can_add_sep: true)
    Permission.super_admin.update_attributes!(can_add_sep: true)
    Permission.hbx_tier3.update_attributes!(can_add_sep: true)
  end

  def hbx_admin_can_lock_unlock
    Permission.hbx_staff.update_attributes(can_lock_unlock: true)
  end

  def hbx_admin_can_view_username_and_email
    Permission.hbx_staff.update_attributes!(can_view_username_and_email: true)
    Permission.super_admin.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_tier3.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_read_only.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_tier1.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_tier2.update_attributes!(can_view_username_and_email: true)
  end

  def hbx_admin_can_reset_password
    Permission.hbx_staff.update_attributes(can_reset_password: true)
  end

  def hbx_admin_can_change_fein
    Permission.super_admin.update_attributes(can_change_fein: true)
    Permission.hbx_tier3.update_attributes(can_change_fein: true)
  end

  def hbx_admin_can_force_publish
    Permission.super_admin.update_attributes(can_force_publish: true)
    Permission.hbx_tier3.update_attributes(can_force_publish: true)
  end

  def hbx_admin_can_extend_open_enrollment
    Permission.hbx_tier3.update_attributes(can_extend_open_enrollment: true)
  end

  def hbx_admin_can_create_benefit_application
    Permission.super_admin.update_attributes(can_create_benefit_application: true)
    Permission.hbx_tier3.update_attributes(can_create_benefit_application: true)
  end

  def hbx_admin_can_access_user_account_tab
    Permission.hbx_staff.update_attributes!(can_access_user_account_tab: true)
    Permission.super_admin.update_attributes!(can_access_user_account_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_user_account_tab: true)
  end

  def hbx_admin_can_send_secure_message
    Permission.super_admin.update_attributes(can_send_secure_message: true)
    Permission.hbx_tier3.update_attributes(can_send_secure_message: true)
  end

  def make_all_permissions
    define_permissions
    hbx_admin_can_update_ssn
    hbx_admin_can_complete_resident_application
    hbx_admin_can_add_sep
    hbx_admin_can_lock_unlock
    hbx_admin_can_view_username_and_email
    hbx_admin_can_reset_password
    hbx_admin_can_change_fein
    hbx_admin_can_force_publish
    hbx_admin_can_extend_open_enrollment
    hbx_admin_can_create_benefit_application
    hbx_admin_can_access_user_account_tab
    hbx_admin_can_send_secure_message
  end

  def create_indexes
    Person.create_indexes
  end
end

World(PermissionsWorld)

Given(/all permissions are present$/) do
  define_permissions
  make_all_permissions
  create_indexes
end
