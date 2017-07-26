When(/^Admin enters employers hbx id and press enter$/) do
  page.find("input[type='search']").set("123456")
end

Then(/^Admin should see the matched employer record form$/) do
  expect(page).to have_content("123456")
  expect(page).to have_no_content("67890")
end