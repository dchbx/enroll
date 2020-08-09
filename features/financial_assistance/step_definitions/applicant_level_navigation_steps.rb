When(/^the user clicks ADD\/EDIT INCOME & COVERAGE INFO button for a given household member$/) do
  click_link 'ADD INCOME & COVERAGE INFO'
end

Then(/^the user will navigate to the Tax Info page for the corresponding applicant\.$/) do
  expect(page).to have_content('Household Info: Family Members')
end

Given(/^that the user is on the Tax Info page for a given applicant$/) do
  visit financial_assistance.go_to_step_application_applicant_path(application, application.primary_applicant, 1)
end

When(/^the user clicks My Household section on the left navigation$/) do
  click_link 'My Household'
end

Then(/^the user will navigate to the FAA Household Info page for the corresponding application\.$/) do
  visit financial_assistance.edit_application_path(application.id.to_s)
end

When(/^the user clicks Income & Coverage section on the left navigation$/) do
  expect(page).to have_content('Income and Coverage Info')
end

Then(/^the cursor will display disabled\.$/) do
  page.html.should include('cna')
end

When(/^the user clicks Tax Info section on the left navigation$/) do
  click_link 'Tax Info'
end

When(/^the user clicks Job Income section on the left navigation$/) do
  click_link 'Job Income'
end

Then(/^the user will navigate to the Job Income page for the corresponding applicant$/) do
  visit financial_assistance.edit_application_path(application.id.to_s)
end

When(/^the user clicks Other Income section on the left navigation$/) do
  click_link 'Other Income'
end

Then(/^the user will navigate to the Other Income page for the corresponding applicant\.$/) do
  visit financial_assistance.other_application_applicant_incomes_path(application, application.primary_applicant)
end

When(/^the user clicks Income Adjustments section on the left navigation$/) do
  click_link 'Income Adjustments'
end

Then(/^the user will navigate to the Income Adjustments page for the corresponding applicant$/) do
  visit financial_assistance.application_applicant_deductions_path(application, application.primary_applicant)
end

When(/^the user clicks Health Coverage section on the left navigation$/) do
  click_link 'Health Coverage'
end

Then(/^the user will navigate to the Health Coverage page for the corresponding applicant$/) do
  visit financial_assistance.application_applicant_benefits_path(application, application.primary_applicant)
end

When(/^the user clicks Other Questions section on the left navigation$/) do
  click_link 'Other Questions'
end

Then(/^the user will navigate to the Other Questions page for the corresponding applicant$/) do
  visit financial_assistance.other_questions_application_applicant_path(application, application.primary_applicant)
end