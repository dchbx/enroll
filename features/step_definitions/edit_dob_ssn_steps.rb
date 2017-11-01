

Then(/^Hbx Admin should see the list of primary applicants and an Action button$/) do
	#expect(page).to have_content('Families')
  find_button('Actions').visible?
end

When(/^Hbx Admin clicks on the Action button$/) do
  find(:xpath, "//*[@id='dropdownMenu1']", :wait => 10).trigger("click")
end

Then(/^Hbx Admin should see an edit DOB\/SSN link$/) do
  find_link('Edit DOB / SSN').visible?
end

When(/^Hbx Admin clicks on edit DOB\/SSN link$/) do
  click_link('Edit DOB / SSN')
end

When(/^Hbx Admin enters an invalid SSN and clicks on update$/) do
  fill_in 'person[ssn]', :with => '212-31-31'
  page.find_button("Update").trigger("click")
end

Then(/^Hbx Admin should see the edit form being rendered again with a validation error message$/) do
  expect(page).to have_content(/Edit DOB \/ SSN/i)
  expect(page).to have_content(/SSN must be 9 digits/i)
end

When(/^Hbx Admin enters a valid DOB and SSN and clicks on update$/) do
  fill_in 'person[ssn]', :with => '212-31-3131'
  page.find_button("Update").trigger("click")
end

Then(/^Hbx Admin should see the update partial rendered with update sucessful message$/) do
  expect(page).to have_content(/DOB \/ SSN Update Successful/i)
end
