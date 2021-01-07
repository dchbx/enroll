require File.join(Rails.root, "lib/migration_task")

class DefinePermissions < MigrationTask
#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'

  def initial_hbx
    Permission
      .find_or_initialize_by(name: 'hbx_staff')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                          send_broker_agency_message: true, approve_broker: true, approve_ga: true, can_update_ssn: false, can_complete_resident_application: false,
                          can_add_sep: false, can_lock_unlock: true, can_view_username_and_email: false, can_reset_password: false, modify_admin_tabs: true,
                          view_admin_tabs: true,  view_the_configuration_tab: true, can_submit_time_travel_request: false,
                          view_agency_staff: true, manage_agency_staff: true, can_access_pay_now: true, can_access_age_off_excluded: true)
    Permission
      .find_or_initialize_by(name: 'hbx_read_only')
      .update_attributes!(modify_family: true, modify_employer: false, revert_application: false, list_enrollments: true,
                          send_broker_agency_message: false, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: true,
                          view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission
      .find_or_initialize_by(name: 'hbx_csr_supervisor')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                          send_broker_agency_message: false, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: false,
                          view_the_configuration_tab: true, can_submit_time_travel_request: false, can_access_pay_now: true, can_access_age_off_excluded: true)
    Permission
      .find_or_initialize_by(name: 'hbx_csr_tier2')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: false, list_enrollments: false,
                          send_broker_agency_message: false, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: false,
                          view_the_configuration_tab: true, can_submit_time_travel_request: false, can_access_pay_now: true, can_access_age_off_excluded: true)
    Permission
      .find_or_initialize_by(name: 'hbx_csr_tier1')
      .update_attributes!(modify_family: true, modify_employer: false, revert_application: false, list_enrollments: false,
                          send_broker_agency_message: false, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: false,
                          view_the_configuration_tab: true, can_submit_time_travel_request: false, can_access_pay_now: true, can_access_age_off_excluded: true)
    Permission
      .find_or_initialize_by(name: 'developer')
      .update_attributes!(modify_family: false, modify_employer: false, revert_application: false, list_enrollments: true,
                          send_broker_agency_message: false, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: true,
                          view_the_configuration_tab: true, can_submit_time_travel_request: false)
    Permission
      .find_or_initialize_by(name: 'hbx_tier3')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                          send_broker_agency_message: true, approve_broker: true, approve_ga: true, can_update_ssn: false, can_complete_resident_application: false,
                          can_add_sep: false, can_lock_unlock: false, can_view_username_and_email: false, can_reset_password: false, modify_admin_tabs: true,
                          view_admin_tabs: true,  view_the_configuration_tab: true, can_submit_time_travel_request: false, view_agency_staff: true,
                          manage_agency_staff: true, can_send_secure_message: true, can_manage_qles: true, can_access_pay_now: true, can_access_age_off_excluded: true
                        )
    Permission
      .find_or_initialize_by(name: 'super_admin')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                          send_broker_agency_message: true, approve_broker: true, approve_ga: true, can_update_ssn: false, can_complete_resident_application: false,
                          can_add_sep: false, can_lock_unlock: true, can_view_username_and_email: false, can_reset_password: false, modify_admin_tabs: true,
                          view_admin_tabs: true, can_extend_open_enrollment: true, view_the_configuration_tab: true, can_submit_time_travel_request: false, view_agency_staff: true,
                          manage_agency_staff: true, can_send_secure_message: true, can_manage_qles: true, can_access_pay_now: true, can_access_age_off_excluded: true
                        )
      #puts 'Permissions Updated!'
  end

  def assign_current_permissions
    initial_hbx
    hbx_admin_can_update_ssn
    hbx_admin_can_access_user_account_tab
    hbx_admin_can_view_login_history
    hbx_admin_csr_view_personal_info_page
    hbx_admin_can_complete_resident_application
    hbx_admin_can_add_sep
    hbx_admin_can_lock_unlock
    hbx_admin_can_add_pdc
    hbx_admin_can_view_username_and_email
    hbx_admin_can_reset_password
    hbx_admin_can_change_fein
    hbx_admin_can_force_publish
    hbx_admin_can_send_secure_message
    hbx_admin_can_modify_plan_year
    hbx_admin_can_extend_open_enrollment
    hbx_admin_can_create_benefit_application
    hbx_admin_can_view_application_types
    hbx_admin_can_access_new_consumer_application_sub_tab
    hbx_admin_can_access_identity_verification_sub_tab
    hbx_admin_can_access_outstanding_verification_sub_tab
    hbx_admin_can_access_accept_reject_identity_documents
    hbx_admin_can_access_accept_reject_paper_application_documents
    hbx_admin_can_transition_family_members
    hbx_admin_can_delete_identity_application_documents
    hbx_admin_can_access_pay_now
    hbx_admin_can_access_age_off_excluded
    hbx_admin_can_manage_qles
  end

  def build_test_roles
    User.where(email: /themanda.*dc.gov/).delete_all
    Person.where(last_name: /^amanda\d+$/).delete_all
    a=10000000
    u1 = User.create( email: 'themanda.staff@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u2 = User.create( email: 'themanda.readonly@dc.gov', password: 'P@55word', password_confirmation: 'P@55word',  oim_id: "ex#{rand(5999999)+a}")
    u3 = User.create( email: 'themanda.csr_supervisor@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u4 = User.create( email: 'themanda.csr_tier1@dc.gov', password: 'P@55word', password_confirmation: 'P@55word',  oim_id: "ex#{rand(5999999)+a}")
    u5 = User.create( email: 'themanda.csr_tier2@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u6 = User.create( email: 'developer@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u7 = User.create( email: 'themanda.csr_tier3@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u8 = User.create( email: 'themanda.super_admin@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")

    hbx_profile_id = FactoryBot.create(:hbx_profile).id
    p1 = Person.create( first_name: 'staff', last_name: "amanda#{rand(1000000)}", user: u1)
    p2 = Person.create( first_name: 'read_only', last_name: "amanda#{rand(1000000)}", user: u2)
    p3 = Person.create( first_name: 'supervisor', last_name: "amanda#{rand(1000000)}", user: u3)
    p4 = Person.create( first_name: 'tier1', last_name: "amanda#{rand(1000000)}", user: u4)
    p5 = Person.create( first_name: 'tier2', last_name: "amanda#{rand(1000000)}", user: u5)
    p6 = Person.create( first_name: 'developer', last_name: "developer#{rand(1000000)}", user: u6)
    p7 = Person.create( first_name: 'tier3', last_name: "amanda#{rand(1000000)}", user: u7)
    p8 = Person.create( first_name: 'super_admin', last_name: "amanda#{rand(1000000)}", user: u8)

    HbxStaffRole.create!( person: p1, permission_id: Permission.hbx_staff.id, subrole: 'hbx_staff', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p2, permission_id: Permission.hbx_read_only.id, subrole: 'hbx_read_only', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p3, permission_id: Permission.hbx_csr_supervisor.id, subrole: 'hbx_csr_supervisor', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p4, permission_id: Permission.hbx_csr_tier1.id, subrole: 'hbx_csr_tier1', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p5, permission_id: Permission.hbx_csr_tier2.id, subrole: 'hbx_csr_tier2', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p6, permission_id: Permission.developer.id, subrole: 'developer', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p7, permission_id: Permission.hbx_tier3.id, subrole: 'hbx_tier3', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p8, permission_id: Permission.super_admin.id, subrole: 'super_admin', hbx_profile_id: hbx_profile_id)
  end

  def hbx_admin_can_update_ssn
    Permission.hbx_staff.update_attributes!(can_update_ssn: true)
    Permission.super_admin.update_attributes!(can_update_ssn: true)
    Permission.hbx_tier3.update_attributes!(can_update_ssn: true)
  end

  def hbx_admin_can_access_user_account_tab
    Permission.hbx_staff.update_attributes!(can_access_user_account_tab: true)
    Permission.super_admin.update_attributes!(can_access_user_account_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_user_account_tab: true)
  end

  def hbx_admin_can_access_age_off_excluded
    Permission.hbx_staff.update_attributes!(can_access_age_off_excluded: true)
    Permission.super_admin.update_attributes!(can_access_age_off_excluded: true)
    Permission.hbx_tier3.update_attributes!(can_access_age_off_excluded: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_age_off_excluded: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_age_off_excluded: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_age_off_excluded: true)
  end

  def hbx_admin_can_view_login_history
    Permission.super_admin.update_attributes!(view_login_history: true)
  end

  def hbx_admin_csr_view_personal_info_page
    Permission.hbx_staff.update_attributes!(view_personal_info_page: true)
    Permission.super_admin.update_attributes!(view_personal_info_page: true)
    Permission.hbx_tier3.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_supervisor.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_tier2.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_tier1.update_attributes!(view_personal_info_page: true)
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
    Permission.hbx_staff.update_attributes(can_lock_unlock: false)
    Permission.super_admin.update_attributes(can_lock_unlock: true)
    Permission.hbx_tier3.update_attributes(can_lock_unlock: false)
  end

  def hbx_admin_can_add_pdc
    Permission.hbx_staff.update_attributes!(can_add_pdc: true)
    Permission.super_admin.update_attributes!(can_add_pdc: true)
    Permission.hbx_tier3.update_attributes!(can_add_pdc: true)
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
    Permission.hbx_staff.update_attributes(can_reset_password: false)
    Permission.super_admin.update_attributes(can_reset_password: true)
    Permission.hbx_tier3.update_attributes(can_reset_password: false)
  end

  def hbx_admin_can_change_fein
    Permission.super_admin.update_attributes(can_change_fein: true)
    Permission.hbx_tier3.update_attributes(can_change_fein: true)
  end

  def hbx_admin_can_force_publish
    Permission.super_admin.update_attributes(can_force_publish: true)
    Permission.hbx_tier3.update_attributes(can_force_publish: true)
  end

  def hbx_admin_can_send_secure_message
    Permission.super_admin.update_attributes(can_send_secure_message: true)
    Permission.hbx_tier3.update_attributes(can_send_secure_message: true)
  end

  def hbx_admin_can_modify_plan_year
    Permission.super_admin.update_attributes(can_modify_plan_year: true)
    Permission.hbx_tier3.update_attributes(can_modify_plan_year: true)
  end

  def hbx_admin_can_extend_open_enrollment
    Permission.super_admin.update_attributes!(can_extend_open_enrollment: true)
    Permission.hbx_tier3.update_attributes(can_extend_open_enrollment: true)
  end

  def hbx_admin_can_create_benefit_application
    Permission.super_admin.update_attributes(can_create_benefit_application: true)
    Permission.hbx_tier3.update_attributes(can_create_benefit_application: true)
  end

  def hbx_admin_can_manage_qles
    Permission.super_admin.update_attributes(can_manage_qles: true)
    Permission.hbx_tier3.update_attributes(can_manage_qles: true)
  end

  def grant_super_admin_access
    raise "User Email Argument expected!!"if ENV['user_email'].blank?
    user_emails = ENV['user_email'].split(',')
    hbx_organization = BenefitSponsors::Organizations::Organization.hbx_profiles.first
    users = User.where(:email.in => user_emails)
    users.each do |user|
      HbxStaffRole.create!( person: user.person, permission_id: Permission.super_admin.id, subrole: 'super_admin', hbx_profile_id: HbxProfile.current_hbx.id, benefit_sponsor_hbx_profile_id: hbx_organization.hbx_profile.id)
    end
  end

  def grant_hbx_tier3_access
    raise "User Email Argument expected!!"if ENV['user_email'].blank?
    user_emails = ENV['user_email'].split(',')
    hbx_organization = BenefitSponsors::Organizations::Organization.hbx_profiles.first
    users = User.where(:email.in => user_emails)
    users.each do |user|
      HbxStaffRole.create!( person: user.person, permission_id: Permission.hbx_tier3.id, subrole: 'hbx_tier3', hbx_profile_id: HbxProfile.current_hbx.id, benefit_sponsor_hbx_profile_id: hbx_organization.hbx_profile.id)
    end
  end

  def hbx_admin_can_view_application_types
    Permission.hbx_staff.update_attributes!(can_view_application_types: true)
    Permission.super_admin.update_attributes!(can_view_application_types: true)
    Permission.hbx_tier3.update_attributes!(can_view_application_types: true)
  end

  def hbx_admin_can_access_new_consumer_application_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.super_admin.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_new_consumer_application_sub_tab: true)
  end

  def hbx_admin_can_access_identity_verification_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.super_admin.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_identity_verification_sub_tab: true)
  end

  def hbx_admin_can_access_outstanding_verification_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_outstanding_verification_sub_tab: true)
    Permission.super_admin.update_attributes!(can_access_outstanding_verification_sub_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_outstanding_verification_sub_tab: true)
  end

  def hbx_admin_can_access_accept_reject_identity_documents
    Permission.hbx_staff.update_attributes!(can_access_accept_reject_identity_documents: true)
    Permission.super_admin.update_attributes!(can_access_accept_reject_identity_documents: true)
    Permission.hbx_tier3.update_attributes!(can_access_accept_reject_identity_documents: true)
  end

  def hbx_admin_can_access_accept_reject_paper_application_documents
    Permission.hbx_staff.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.super_admin.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_tier3.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_accept_reject_paper_application_documents: true)
  end
  def hbx_admin_can_transition_family_members
   Permission.hbx_staff.update_attributes!(can_transition_family_members: true)
   Permission.super_admin.update_attributes!(can_transition_family_members: true)
   Permission.hbx_tier3.update_attributes!(can_transition_family_members: true)
  end

  def hbx_admin_can_delete_identity_application_documents
    Permission.hbx_staff.update_attributes!(can_delete_identity_application_documents: true)
    Permission.super_admin.update_attributes!(can_delete_identity_application_documents: true)
    Permission.hbx_tier3.update_attributes!(can_delete_identity_application_documents: true)
  end

  def hbx_admin_can_access_pay_now
    Permission.hbx_staff.update_attributes!(can_access_pay_now: true)
    Permission.super_admin.update_attributes!(can_access_pay_now: true)
    Permission.hbx_tier3.update_attributes!(can_access_pay_now: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_pay_now: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_pay_now: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_pay_now: true)
  end

end
