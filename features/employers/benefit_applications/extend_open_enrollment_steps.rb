# frozen_string_literal: true

Then(/^the table will expand displaying the Extend Open Enrollment table$/) do
  expect(page).to have_css('#extendable_applications_table')
  expect(page).to have_css('h4.heading-text', text: 'Extend Open Enrollment')
end

Then(/^the Choose New Open Enrollment Date panel is presented$/) do
  expect(page).to have_css('.edit_open_enrollment_fields')
  find('input[value="Extend Open Enrollment"]')
end

Then(/^a Successfully extended employer\(s\) open enrollment success message will display\.$/) do
  expect(page).to have_css('.alert.alert-success', text: 'Successfully extended employer(s) open enrollment.')
end

When(/^the user fills out the Extend Open Enrollment form with a new date$/) do
  # After effective date
  fill_in('open_enrollment_end_date', with: (Date.today + 1.year).to_s)
end

When(/^the user clicks the Extend Open Enrollment to submit the form$/) do
  inputs = page.all('input')
  extension_button = inputs.detect { |input| input[:value] == 'Extend Open Enrollment' }
  extension_button.click
end

Then("the user should see a success message that Open Enrollment was successfully extended") do
  expect(page).to have_content('Successfully extended employer(s) open enrollment.')
end