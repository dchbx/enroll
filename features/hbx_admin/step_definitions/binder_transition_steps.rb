module BinderTransitionWorld
  def hbx_admin(*traits)
    attributes = traits.extract_options!
    @hbx_admin ||= FactoryGirl.create :user, *traits, attributes
  end

  def employer(*traits)
    attributes = traits.extract_options!
    @employer ||= FactoryGirl.create :employer, *traits, attributes
  end
end
World(BinderTransitionWorld)

Given(/^an HBX admin exists$/) do
  hbx_admin :with_family, :hbx_staff
end

Given(/^a new employer, with insured employees, exists$/) do
  employer :with_insured_employees
end

Given(/^the HBX admin is logged in$/) do
  login_as hbx_admin, scope: :user
end

Given(/^the HBX admin visits the Dashboard page$/) do
  # pending # Write code here that turns the phrase above into concrete actions
  visit exchanges_hbx_profiles_root_path
  find('.interaction-click-control-binder').click
  expect(page).to have_content('Employers who are eligible for binder paid')
end

When(/^the HBX admin selects the employer to confirm$/) do
  # pending # Write code here that turns the phrase above into concrete actions
  binding.pry
  sleep(5)
  expect(false).to be_truthy
end

Then(/^the HBX admin sees a checklist$/) do |checklist|
  # table is a Cucumber::Core::Ast::DataTable
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the employer meets requirements$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the HBX admin has confirmed requirements for the employer$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the employer remits initial binder payment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the DCHBX confirms binder payment has been received by third\-party processor$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin has verified new \(initial\) Employer meets minimum participation requirements \((\d+)\/(\d+) rule\)$/) do |arg1, arg2|
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^a sufficient number of 'non\-owner' employee\(s\) have enrolled and\/or waived in Employer\-sponsored benefits$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the initiate "([^"]*)" button will be active$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the employer has remitted the initial binder payment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin visits the page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin clicks the "([^"]*)" button$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^then the Employer’s state transitions to "Binder Paid”$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the Group XML is generated for the Employer$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the employer is renewing$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin visits the last other blank page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin visits the other blank page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the HBX\-Admin can utilize the “Transmit EDI” button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end
