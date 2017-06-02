
Then (/^Hbx Admin sees Families index$/) do
  expect(page).to have_text("Families")
end

When(/^Hbx Admin clicks on Families tab$/) do
  click_link "Families"
end

Then(/^Hbx Admin should see an Actions link$/) do
  expect(page).to have_text("Actions")
end

When(/^Hbx Admin clicks on the Actions button$/) do
  click_button "Actions"
end

Then(/^Hbx Admin should see an Enable \/ Disable link$/) do
  find_link('Enable / Disable').visible?
end

When(/^Hbx Admin clicks on the Enable \/ Disable link$/) do
  click_link "Enable / Disable"
end

Then(/^Hbx Admin should see the person record disabled$/) do
  wait_for_ajax(3)
  expect(page).to have_text("Disabled user John Smith1") 
end