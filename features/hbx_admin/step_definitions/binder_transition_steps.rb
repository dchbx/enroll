module BinderTransitionWorld
  include ApplicationHelper

  def employer(*traits)
    attributes = traits.extract_options!
    @employer ||= FactoryGirl.create :employer, *traits, attributes
  end
end
World(BinderTransitionWorld)

Given(/^a new employer, with insured employees, exists$/) do
  # employer :with_insured_employees
end

Given(/^the HBX admin visits the Dashboard page$/) do
  # visit exchanges_hbx_profiles_root_path
end

And(/^the HBX admin clicks the Binder Transition tab$/) do
  # page.find('.interaction-click-control-employers').click
  # page.find("h1").should have_content("Employers")
end

And(/^the HBX admin sees a checklist$/) do |checklist|
  # page.find(".fa-info-circle")
end

When(/^the HBX admin selects the employer to confirm$/) do
  # sleep 1
  # find('label[for=input_0]').click
end

Then(/^the initiate "([^"]*)" button will be active$/) do |arg1|
end

And(/^the HBX admin clicks the "([^"]*)" button$/) do |arg1|
  # first('.header .dropdown-menu a', visible: false).trigger('click')
  # sleep 1
end

Then(/^then the Employer’s state transitions to "([^"]*)"$/) do |arg1|
  # employer.reload
  # expect(employer.employer_profile.aasm_state.titleize).to eq arg1
end

Given(/^the employer meets requirements$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the HBX admin has confirmed requirements for the employer$/) do
  # step "the HBX admin clicks the Binder Transition tab"
  # step "the HBX admin selects the employer to confirm"
end

When(/^the employer remits initial binder payment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the DCHBX confirms binder payment has been received by third\-party processor$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin has verified new \(initial\) Employer meets minimum participation requirements \((\d+)\/(\d+) rule\)$/) do |arg1, arg2|
  # page.find(".fa-info-circle")
end

When(/^a sufficient number of 'non\-owner' employee\(s\) have enrolled and\/or waived in Employer\-sponsored benefits$/) do
  # page.find(".fa-info-circle")
end

Given(/^the employer has remitted the initial binder payment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the Group XML is generated for the Employer$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the employer is renewing$/) do
  # py = employer.employer_profile.plan_years.last
  # py.aasm_state = "renewing_enrolling"
  # py.save
end

Then(/^the HBX\-Admin can utilize the “Transmit EDI” button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^a button to transmit the Employer's Group XML will be active$/) do
  # step "the HBX admin clicks the Binder Transition tab"
  # expect(page).to have_css(".transmit-group-xml")
  # expect(page).to have_link('Transmit XML')
end

When(/^the HBX\-Admin clicks the button to transmit the Employer's Group XML$/) do
  # expect(page).to have_css(".transmit-group-xml")
  # page.find(".transmit-group-xml").click
end

Then(/^the appropriate XML file is generated and transmitted$/) do
  # expect(page).to have_css(".alert-notice", text: "Successfully transmitted the employer group xml.")
end
