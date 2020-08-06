# frozen_string_literal: true

Then(/^Hbx Admin should see buttons to filter$/) do
  expect(page).to have_content('Employee')
  expect(page).to have_content('Broker')
  expect(page).to have_content('Employer')
  expect(page).to have_content('All')
  expect(page).to have_content('CSV')
  # at present we do not have clear implementation thoughts about bulk action on user account data-table
  # expect(page).to have_content('Bulk Actions')
end

Then(/^Hbx Admin should see text Account Updates$/) do
  expect(page).to have_content('Account Updates')
end

Then(/^Hbx Admin should see columns related to user account$/) do
  expect(page).to have_content('USERNAME')
  expect(page).to have_content('SSN')
  expect(page).to have_content('DOB')
  expect(page).to have_content('HBX ID')
  expect(page).to have_content('EMAIL')
  expect(page).to have_content('Status')
  expect(page).to have_content('Role Type')
  expect(page).to have_content('Actions')
end

When(/^I click Employee button$/) do
  find(:xpath, '//*[@id="Tab:all_employee_roles"]').click
end

When(/^I click Employee and Locked button$/) do
  find(:xpath, '//*[@id="Tab:all_employee_roles"]').click
  find(:xpath, '//*[@id="Tab:all_employee_roles-locked"]').click
end

When(/^I click Employee and Unlocked button$/) do
  find(:xpath, '//*[@id="Tab:all_employee_roles"]').click
  find(:xpath, '//*[@id="Tab:all_employee_roles-unlocked"]').click
end

Then(/^I should only see user with employee role$/) do
  expect(page).to have_content(employee_role.oim_id)
  expect(page).not_to have_content(employer_staff.oim_id)
  expect(page).not_to have_content(broker.oim_id)
  expect(page).to have_content("Locked")
  expect(page).to have_content("Unlocked")
end

Then(/^I should see subrole field on datatable$/) do
  expect(page).to have_content("Permission level")
end

When(/^I click All button$/) do
  find(:xpath, '//*[@id="Tab:all"]').click
end

Then(/^I should see users with any role$/) do
  expect(page).to have_content(employee_role.oim_id)
  expect(page).to have_content(employer_staff.oim_id)
  expect(page).to have_content(broker.oim_id)
  expect(page).to have_content("Locked")
  expect(page).to have_content("Unlocked")
end

When(/^I click Employer button$/) do
  find(:xpath, '//*[@id="Tab:all_employer_staff_roles"]').click
end

Then(/^I should only see user with employer staff role$/) do
  expect(page).not_to have_content(employee_role.oim_id)
  expect(page).not_to have_content(broker.oim_id)
  expect(page).to have_content(employer_staff.oim_id)
  expect(page).to have_content("Locked")
  expect(page).to have_content("Unlocked")
end

When(/^I click Broker button$/) do
  find(:xpath, '//*[@id="Tab:all_broker_roles"]').click
end

Then(/^I should only see user with broker role$/) do
  expect(page).not_to have_content(employee_role.oim_id)
  expect(page).not_to have_content(employer_staff.oim_id)
  expect(page).to have_content(broker.oim_id)
  expect(page).to have_content("Locked")
  expect(page).to have_content("Unlocked")
end

When(/^a user enters (.*) user oim_id in search box$/) do |user_role|
  case user_role
  # Add to this as necessary
  when 'Employee Role'
    user = employee_role
  end
  page.find("input[type='search']").set(user.oim_id)
end

Then(/^a user should see a result with (.*) user oim_id and not (.*) user oim_id$/) do |result_user_role, non_result_user_role|
  case result_user_role
  when 'Employee Role'
    result_user = employee_role
  end
  case non_result_user_role
  when 'Broker'
    non_result_user = broker
  end
  expect(page).to have_content(result_user.oim_id)
  expect(page).to have_no_content(non_result_user.oim_id)
end

When(/^a user enters (.*) user email$/) do |user_role|
  case user_role
  # Add to this as necessary
  when 'Employee Role'
    user = employee_role
  end
  page.find("input[type='search']").set(user.email)
end

Then(/^a user should see a result with (.*) user email and not (.*) user email$/) do |result_user_role, non_result_user_role|
  case result_user_role
  when 'Employee Role'
    result_user = employee_role
  end
  case non_result_user_role
  when 'Broker'
    non_result_user = broker
  end
  expect(page).to have_content(result_user.email)
  expect(page).to have_no_content(non_result_user.email)
end

Then(/^Hbx Admin click on User Accounts$/) do
  find(:xpath, '//*[@id="myTab"]/li[6]/a').click
end
