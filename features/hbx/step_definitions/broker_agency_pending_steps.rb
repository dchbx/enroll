
Then(/^Hbx Admin checks Kaiser Foundation$/) do
  find(:xpath, "//label[input[@name='person[broker_role_attributes][carrier_appointments][Kaiser Foundation]']]").trigger('click')
end

Then(/^Hbx Admin checks Optimum Choice$/) do
  find(:xpath, "//label[input[@name='person[broker_role_attributes][carrier_appointments][Optimum Choice]']]").trigger('click')
end

When(/^Hbx Admin clicks pending button$/) do
  click_button "Pending"
end

Then(/^Hbx Admin sees a successful message$/) do
  expect(page).to have_content('Broker applicant is now pending.')
end