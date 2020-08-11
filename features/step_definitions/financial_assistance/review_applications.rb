# frozen_string_literal: true

Given(/^that a family has a Financial Assistance application in the (.*?) state$/) do |state|
  application.update_attributes(aasm_state: state)
end

And(/^the user navigates to the “Help Paying For Coverage” portal$/) do
  visit financial_assistance.applications_path
end

<<<<<<< HEAD
When(/^the user clicks the “Action” dropdown corresponding to the .*? application$/) do
=======
When(/^the user clicks the “Action” dropdown corresponding to the (.*?) application$/) do |state|
>>>>>>> 0d9d5e0... review applications feature
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
