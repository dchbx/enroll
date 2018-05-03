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

  def hbx_admin_with_subrole(subrole)
    @u1 = User.create( email: 'hbx_admin_role@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: 'hbx_admin_role@dc.gov', roles: ["hbx_staff"])
    hbx_profile_id = FactoryGirl.create(:hbx_profile).id
    p1 = Person.create( first_name: 'staff', last_name: "amanda#{rand(1000000)}", user: @u1)
    permission_hbx_staff = FactoryGirl.create(:permission, :hbx_staff)
    HbxStaffRole.create!( person: p1, permission_id: permission_hbx_staff.id, subrole: subrole, hbx_profile_id: hbx_profile_id)
  end
end
World(HbxAdminWorld)

Given(/^an HBX admin exists$/) do
  hbx_admin :with_family, :hbx_staff
end

Given(/^the HBX admin is logged in$/) do
  login_as hbx_admin, scope: :user
end

Given(/^a Hbx admin with hbx_staff role exists$/) do
  hbx_admin_with_subrole 'hbx_staff'
end

Given(/^a Hbx admin with hbx_read_only role exists$/) do
  hbx_admin_with_subrole 'hbx_read_only'
end

Given(/^a Hbx admin with hbx_csr_supervisor role exists$/) do
  hbx_admin_with_subrole 'hbx_csr_supervisor'
end

Given(/^a Hbx admin with hbx_csr_tier1 role exists$/) do
  hbx_admin_with_subrole 'hbx_csr_tier1'
end

Given(/^a Hbx admin with hbx_csr_tier2 role exists$/) do
  hbx_admin_with_subrole 'hbx_csr_tier2'
end

Given(/^a Hbx admin logs on to Portal$/) do
  visit "/users/sign_in"
  fill_in "user[login]", :with => @u1.oim_id
  fill_in "user[password]", :with => @u1.password
  find('.interaction-click-control-sign-in').click
  visit exchanges_hbx_profiles_root_path
end
