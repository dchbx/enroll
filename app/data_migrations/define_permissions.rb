require File.join(Rails.root, "lib/migration_task")

class DefinePermissions < MigrationTask 
#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'

  def initial_hbx
    Permission.where(name: /^hbx/).delete_all   
  	Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
  	  send_broker_agency_message: true, approve_broker: true, approve_ga: true,
  	  modify_admin_tabs: true, view_admin_tabs: true)
    Permission.create(name: 'hbx_read_only', modify_family: true, modify_employer: false, revert_application: false, list_enrollments: true,
  	  send_broker_agency_message: false, approve_broker: false, approve_ga: false,
  	  modify_admin_tabs: false, view_admin_tabs: true)  
  	Permission.create(name: 'hbx_csr_supervisor', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
  	  send_broker_agency_message: false, approve_broker: false, approve_ga: false,
  	  modify_admin_tabs: false, view_admin_tabs: false)
  	Permission.create(name: 'hbx_csr_tier2', modify_family: true, modify_employer: true, revert_application: false, list_enrollments: false,
  	  send_broker_agency_message: false, approve_broker: false, approve_ga: false,
  	  modify_admin_tabs: false, view_admin_tabs: false)  
    Permission.create(name: 'hbx_csr_tier1', modify_family: true, modify_employer: false, revert_application: false, list_enrollments: false,
  	  send_broker_agency_message: false, approve_broker: false, approve_ga: false,
  	  modify_admin_tabs: false, view_admin_tabs: false)
    Permission.create(name: 'developer', modify_family: false, modify_employer: false, revert_application: false, list_enrollments: true,
      send_broker_agency_message: false, approve_broker: false, approve_ga: false,
      modify_admin_tabs: false, view_admin_tabs: true)
  	permission = Permission.hbx_staff
    Person.where(hbx_staff_role: {:$exists => true}).all.each{|p|p.hbx_staff_role.update_attributes(permission_id: permission.id, subrole:'hbx_staff')}
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
    hbx_profile_id = FactoryGirl.create(:hbx_profile).id
    p1 = Person.create( first_name: 'staff', last_name: "amanda#{rand(1000000)}", user: u1)
    p2 = Person.create( first_name: 'read_only', last_name: "amanda#{rand(1000000)}", user: u2)
    p3 = Person.create( first_name: 'supervisor', last_name: "amanda#{rand(1000000)}", user: u3)
    p4 = Person.create( first_name: 'tier1', last_name: "amanda#{rand(1000000)}", user: u4)
    p5 = Person.create( first_name: 'tier2', last_name: "amanda#{rand(1000000)}", user: u5)
    p6 = Person.create( first_name: 'developer', last_name: "developer#{rand(1000000)}", user: u6)
    HbxStaffRole.create!( person: p1, permission_id: Permission.hbx_staff.id, subrole: 'hbx_staff', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p2, permission_id: Permission.hbx_read_only.id, subrole: 'hbx_read_only', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(  person: p3, permission_id: Permission.hbx_csr_supervisor.id, subrole: 'hbx_csr_supervisor', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p4, permission_id: Permission.hbx_csr_tier1.id, subrole: 'hbx_csr_tier1', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p5, permission_id: Permission.hbx_csr_tier2.id, subrole: 'hbx_csr_tier2', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p6, permission_id: Permission.hbx_csr_tier2.id, subrole: 'developer', hbx_profile_id: hbx_profile_id)
  end
  def hbx_admin_can_update_ssn
    Permission.hbx_staff.update_attributes(can_update_ssn: true)
  end
end