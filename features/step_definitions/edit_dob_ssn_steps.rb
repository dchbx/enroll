Then(/^Hbx Admin should see the list of primary applicants and an Action button$/) do
  within('.effective-datatable') do
    expect(page).to have_css('.dropdown-toggle', count: 1)
  end
end

Then(/^Hbx Admin should see the list of user accounts and an Action button$/) do
  within('.effective-datatable') do
    expect(page).to have_css('.dropdown-toggle', count: 2)
  end
end

# FIXME: Make this take a 'for' argument, that way we can select which user
When(/^Hbx Admin clicks on the Action button$/) do
  within('.effective-datatable') do
    find_all('.dropdown-toggle', :wait => 10).last.click
  end
end

# FIXME: Make this take a 'for' argument, that way we can select which user
Then(/^Hbx Admin should see an edit DOB\/SSN link$/) do
  find_link('Edit DOB / SSN').visible?
end

# FIXME: Make this take a 'for' argument, that way we can select which user
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
