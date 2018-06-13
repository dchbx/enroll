
Then(/^Hbx Admin checks FCHP$/) do
  find(:xpath, "//label[input[@name='person[broker_role_attributes][carrier_appointments][FCHP]']]").trigger('click')
end

Then(/^Hbx Admin checks Guardian$/) do
  find(:xpath, "//label[input[@name='person[broker_role_attributes][carrier_appointments][Guardian]']]").trigger('click')
end

When(/^Hbx Admin clicks pending button$/) do
  click_button "Pending"
end

Then(/^Hbx Admin sees a successful message$/) do
  expect(page).to have_content('Broker applicant is now pending.')
end