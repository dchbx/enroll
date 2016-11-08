

Then(/^Hbx Admin should see the list of primary applicants and an Edit DOB\/SSN button$/) do
	expect(page).to have_content('Families')
	expect(page).to have_content('Primary Applicant')
	expect(page).to have_content('Edit DOB/SSN')
end

When(/^Hbx Admin clicks on the Edit DOB\/SSN button$/) do
	click_link "Edit DOB\/SSN" 
end

Then(/^Hbx Admin should see the edit DOB\/SSN form$/) do
 expect(page).to have_content('Editing DOB / SSN for:')
 expect(page).to have_field("jq_datepicker_ignore_person[dob]")
 expect(page).to have_field("person[ssn]")
 page.should have_selector(:link_or_button, 'Update')
end

When(/^Hbx Admin enters an invalid SSN and clicks on update$/) do
  fill_in 'person[ssn]', :with => '212-31-31'
  click_button "Update"
end

Then(/^Hbx Admin should see the edit form being rendered again with a validation error message$/) do
  expect(page).to have_content('Editing DOB / SSN for:')
  expect(page).to have_content('SSN must be 9 digits')
end

When(/^Hbx Admin enters a valid DOB and SSN and clicks on update$/) do
  fill_in 'person[ssn]', :with => '212-31-3131'
  click_button "Update"
end

Then(/^Hbx Admin should see the update partial rendered with update sucessful message$/) do
  expect(page).to have_content('DOB / SSN Update Successful')
end
