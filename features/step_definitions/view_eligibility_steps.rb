Given(/^that a family has a Financial Assistance application in the “draft” state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  application
end

Given(/^the user navigates to the “Help Paying For Coverage” portal$/) do
  visit financial_assistance_applications_path
end

When(/^the user clicks the “Action” dropdown corresponding to the “draft” application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Then(/^the “View Eligibility Determination” link will be disabled$/) do
  find_link('View Eligibility Determination')['disabled'].should == 'disabled'
end

Given(/^that a family has a Financial Assistance application in the “submitted” state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'submitted')
end

When(/^clicks the “Action” dropdown corresponding to the “submitted” application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a family has a Financial Assistance application in the “determination_response_error” state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'determination_response_error')
end

When(/^the user clicks the “Action” dropdown corresponding to the “determination_response_error” application$/) do
  find_button('Actions').visible?
  click_button('Actions')
  screenshot_and_post_to_slack('application_index_page_screenshot', channel: 'new_faa_team')
end

Given(/^that a family has a Financial Assistance application in the “determined” state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'determined')
end

When(/^clicks the “Action” dropdown corresponding to the “determined” application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Then(/^the “View Eligibility Determination” link will be actionable$/) do
  find_link('View Eligibility Determination').visible?
  click_link('View Eligibility Determination')
end

Given(/^clicks the “View Eligibility Determination” link$/) do
  find_link('View Eligibility Determination').visible?
  click_link('View Eligibility Determination')
end

Then(/^the user will navigate to the Eligibility Determination page for that specific application$/) do
  expect(page).to have_content('Eligibility Results')
end

Given(/^that a family has a Financial Assistance application with tax households$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  allow(application).to receive(:is_application_valid?).and_return(true)
  create_dummy_tax_households(application)
end

Then(/^the user will navigate to the Eligibility Determination page and will not find CSR text present$/) do
  expect(page).to have_content('Eligibility Results')
  expect(page).to have_content('These people are eligible for savings of')
  expect(page).not_to have_content('They also qualify for extra savings called')
end

Then(/^the user will navigate to the Eligibility Determination page and will find CSR text present$/) do
  application.tax_households.first.eligibility_determinations.first.update_attributes!(csr_percent_as_integer: 73)
  expect(page).to have_content('Eligibility Results')
  expect(page).to have_content('These people are eligible for savings of')
  expect(page).to have_content('They also qualify for extra savings called')
end
