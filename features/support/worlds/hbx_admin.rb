module HbxAdminWorld
  def hbx_admin(*traits)
    attributes = traits.extract_options!
    @hbx_admin ||= FactoryGirl.create :user, *traits, attributes
  end
end
World(HbxAdminWorld)

Given(/^an HBX admin exists$/) do
  hbx_admin :with_family, :hbx_staff
end

Given(/^the HBX admin is logged in$/) do
  login_as hbx_admin, scope: :user
end


Given(/^I have logged in as an HBX\-Admin$/) do
  login_as hbx_admin :with_family, :hbx_staff
end
