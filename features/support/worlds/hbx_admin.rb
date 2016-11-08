module HbxAdminWorld
  def hbx_admin(*traits)
    p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true)
    attributes = traits.extract_options!
    @hbx_admin ||= FactoryGirl.create :user, *traits, attributes
    hbx_profile = FactoryGirl.create :hbx_profile
    FactoryGirl.create :hbx_staff_role, person: @hbx_admin.person, hbx_profile: hbx_profile, permission_id: p_staff.id
    @hbx_admin
  end
end
World(HbxAdminWorld)

Given(/^an HBX admin exists$/) do
  hbx_admin :with_family, :hbx_staff
end

Given(/^the HBX admin is logged in$/) do
  login_as hbx_admin, scope: :user
end
