And(/^is logged in$/) do
  login_as user
end

And(/^a benchmark plan exists$/) do
  hbx_profile = FactoryBot.create(:hbx_profile)
  @family = user.primary_family
  application = FactoryBot.create(:financial_assistance_application, family: @family, aasm_state: 'submitted')
  @applications = [application]
end

And(/^the user will navigate to the FAA Household Info page$/) do
  # visit financial_assistance.applications_path
  # find(".dropdown-toggle", :text => "Actions").click
  # click_link 'Review Application'

  visit edit_financial_assistance_application_path application.id.to_s
end

And(/^all applicants are in Info Completed state with all types of income$/) do
  expect(page).not_to have_content("Info Needed")
end

And(/^the user clicks on the CONTINUE button$/) do
  find(".btn", text: "CONTINUE").click
end

Then(/^the user is on the Review Your Application page$/) do
  expect(page).to have_content("Review Your Application")
end


Given(/^the pencil icon displays for each instance of (.*?)$/) do |instance_type|
  # deductions, Wages and salaries income, Self Employment income, Other income
end


And(/^the user clicks the pencil icon for (.*?)$/) do |icon_type|
  # Income Adjustments, Wages and salaries, Self Employment Income, Other Income
end


Then(/^the user should navigate to the (.*?) page$/) do |page|
  # Income Adjustments, Income, Other Income
  # Tax Info, Job Income, Income Adjustments, Health Coverage, Other Questions
  expect(page).to have_content(page)
end


Given(/^the user views the (.*?) row$/) do |row_type|
  # TAX INFO, Income, Income Adjustments, Health Coverage, Other Questions
end


When(/^the user clicks the applicant's pencil icon for (.*?)$/) do |icon_type|
  # TAX INFO, Income, Income Adjustments, Health Coverage, Other Questions
end


And(/^all data should be presented as previously entered$/) do
  expect(page).not_to have_content("Info Needed")
end


And(/^the CONTINUE button is enabled$/) do
  expect(page.find('#btn-continue')[:class]).not_to include("disabled")
end

Then(/^the user should navigate to the Your Preferences page$/) do
  find(".btn", text: "CONTINUE").click
end
