Given(/^that the user is on the FAA Household Info page$/) do
  login_as consumer, scope: :user
  visit financial_assistance.applications_path
  create_plan
  assign_benchmark_plan_id(application)
  click_button "Start new application"
end

Given(/^the applicant has no saved data$/) do
  expect(page).to have_content('Info Needed')
end

When(/^the user clicks the ADD Info Button for a given household member$/) do
  find(".btn", text: "ADD INCOME & COVERAGE INFO").click
end

Given(/^the user is editing an application for financial assistance$/) do
  click_link 'My Household'
end

When(/^the user navigates to the Tax Info page for a given applicant$/) do
  visit financial_assistance.go_to_step_application_applicant_path(application, application.primary_applicant, 1)
end

When(/^Will this person file taxes for <system year>\? has a nil value stored$/) do
  expect(find('#is_required_to_file_taxes_yes')).not_to be_checked
  expect(find('#is_required_to_file_taxes_no')).not_to be_checked
end

When(/^Will this person be claimed as a tax dependent for <system year>\? has a nil value stored$/) do
  expect(find('#is_claimed_as_tax_dependent_yes')).not_to be_checked
  expect(find('#is_claimed_as_tax_dependent_no')).not_to be_checked
end

Then(/^the CONTINUE will be visibly disabled$/) do
  expect(find('.interaction-click-control-continue')['disabled']).to eq("true")
end

Then(/^should not be actionable\.$/) do
  expect(page).to have_selector('.interaction-click-control-continue', visible: false)
end

When(/^Will this person file taxes for <system year>\? does not have a nil value stored$/) do
  choose('is_required_to_file_taxes_no')
end

When(/^Will this person be claimed as a tax dependent for <system year>\? does not have a nil value stored$/) do
  choose('is_claimed_as_tax_dependent_no')
end

Then(/^the CONTINUE will be visibly enabled$/) do
  expect(find('.interaction-click-control-continue')['disabled']).to eq("false")
end

Then(/^should be actionable\.$/) do
  expect(page).to have_selector('.interaction-click-control-continue', visible: true)
end

Given(/^the user is on the Tax Info page for a given applicant$/) do
  visit financial_assistance.go_to_step_application_applicant_path(application, application.primary_applicant, 1)
end

When(/^the user clicks on the CONTINUE button$/) do
  continue_button = page.all('input').detect { |input| input[:type] == 'submit' }
  continue_button.click
end

Then(/^the user will navigate to the Job Income page for the same applicant\.$/) do
  click_link 'Job Income'
end
