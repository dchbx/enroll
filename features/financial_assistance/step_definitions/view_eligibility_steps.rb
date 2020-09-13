# frozen_string_literal: true

Given(/^that a user with a family has a Financial Assistance application in the "draft" state$/) do
  login_as consumer, scope: :user
  visit financial_assistance.applications_path
  create_plan
  application aasm_state: 'draft'
end

Given(/^the user navigates to the "Help Paying For Coverage" portal$/) do
  visit financial_assistance.applications_path
end

When(/^the user clicks the "Action" dropdown corresponding to the "draft" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Then(/^the "View Eligibility Determination" link will be disabled$/) do
  find_link('View Eligibility Determination')['disabled'].should == 'disabled'
end

Given(/^that a user with a family has a Financial Assistance application in the "submitted" state$/) do
  login_as consumer, scope: :user
  visit financial_assistance.applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'submitted')
end

When(/^clicks the "Action" dropdown corresponding to the "submitted" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a user with a family has a Financial Assistance application in the "determination_response_error" state$/) do
  login_as consumer, scope: :user
  visit financial_assistance.applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'determination_response_error')
end

When(/^the user clicks the "Action" dropdown corresponding to the "determination_response_error" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a user with a family has a Financial Assistance application in the "determined" state$/) do
  login_as consumer, scope: :user
  visit financial_assistance.applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'determined')
end

When(/^clicks the "Action" dropdown corresponding to the "determined" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Then(/^the "View Eligibility Determination" link will be actionable$/) do
  find_link('View Eligibility Determination').visible?
  click_link('View Eligibility Determination')
end

Given(/^clicks the "View Eligibility Determination" link$/) do
  find_link('View Eligibility Determination').visible?
  click_link('View Eligibility Determination')
end

Then(/^the user will navigate to the Eligibility Determination page for that specific application$/) do
  expect(page).to have_content('Eligibility Results')
end

Given(/^that a user with a family has a Financial Assistance application with tax households$/) do
  login_as consumer, scope: :user
  visit financial_assistance.applications_path
  create_plan
  allow(application).to receive(:is_application_valid?).and_return(true)
end

Given(/^the user has 0% CSR$/) do
  create_dummy_ineligibility(application)
end

Given(/^the user has a 73% CSR$/) do
  create_dummy_eligibility(application)
end

Then(/^the user will navigate to the Eligibility Determination page and will not find CSR text present$/) do
  expect(page).to have_content('Eligibility Results')
  expect(page).not_to have_content('These people are eligible for savings of')
  expect(page).not_to have_content('They also qualify for extra savings called')
end

Then(/^the user will navigate to the Eligibility Determination page and will find CSR text present$/) do
  expect(page).to have_content('Eligibility Results')
  expect(page).to have_content('These people are eligible for savings of')
  expect(page).to have_content('They also qualify for extra savings called')
end
