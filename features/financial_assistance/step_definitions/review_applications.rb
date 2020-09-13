# frozen_string_literal: true

Given(/^that a family has a Financial Assistance application in the (.*?) state$/) do |state|
  # draft, submitted, determination_response_error, determined
  FactoryBot.create(:hbx_profile)
  @family = user.primary_family
  @applications = [FactoryBot.create(:financial_assistance_application, family: @family, aasm_state: state)]
  application.update_attributes(aasm_state: state)
end

And(/^the user navigates to the “Help Paying For Coverage” portal$/) do
  visit financial_assistance.applications_path
end

When(/^the user clicks the “Action” dropdown corresponding to the (.*?) application$/) do |_status|
  # draft, submitted, determination_response_error, determined
  find(".dropdown-toggle", :text => "Actions").click
end

Then(/^the "Review Application" link will be disabled$/) do
  expect(find_link("Review Application")[:disabled] == 'true')
end

Then(/^the “Review Application” link will be actionable$/) do
  expect(find_link("Review Application")[:disabled] == 'false')
end

And(/^clicks the “Review Application” link$/) do
  click_link 'Review Application'
end

Then(/^the user will navigate to the Review Application page$/) do
  expect(page).to have_content("Review Your Application")
end

And(/^the user fills out the review and submit details$/) do
  sleep 1
  find(".btn", text: "CONTINUE").click
  sleep 1
  choose("mailed_no")
  continue_button = page.all('input').detect { |input| input[:type] == 'submit' }
  continue_button.click
  # Submit Application
  find("#application_medicaid_terms").click
end
