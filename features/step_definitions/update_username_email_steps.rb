# frozen_string_literal: true

Then(/^Hbx Admin Tier 3 sees User Accounts link$/) do
  click_link 'HBX Portal' if page.has_link?('HBX Portal')
  expect(page).to have_text("User Accounts")
end

When(/^Hbx Admin Tier 3 clicks on User Accounts link$/) do
  click_link "User Accounts"
  wait_for_ajax
end

Then(/^Hbx Admin Tier 3 should see the list of primary applicants and an Action button$/) do
  find_button('Actions').visible?
end

When(/^Hbx Admin Tier 3 clicks on the Action button$/) do
  find('.dropdown-toggle', :text => "Actions").click
end

Then(/^Hbx Admin Tier 3 should see an edit user link$/) do
  find_link('Edit User').visible?
end

When(/^Hbx Admin Tier 3 clicks on edit user link$/) do
  click_link('Edit User')
end

When(/^Hbx Admin Tier 3 enters an valid credentials and clicks on submit$/) do
  fill_in 'new_oim_id', :with => 'new_valid_username'
  fill_in 'new_email', :with => 'new_valid@email.com'
  page.find_button("Submit").click
end

When(/^Hbx Admin Tier 3 enters an invalid credentials and clicks on submit$/) do
  fill_in 'new_oim_id', :with => 'inv'
  fill_in 'new_email', :with => 'inv'
  page.find_button("Submit").click
end

Then(/^Hbx Admin Tier 3 should see updated successfully message$/) do
  page.driver.browser.switch_to.alert.accept
  expect(page).to have_content(/User Account Updated Successfully/)
end

Then(/^Hbx Admin Tier 3 should see error message$/) do
  page.driver.browser.switch_to.alert.accept
  expect(page).to have_content(/Email is invalid/)
  expect(page).to have_content(/Username must be at least 8 characters/)
end