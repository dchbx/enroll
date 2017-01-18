Then(/^Hbx Admin should see searchbox$/) do
  page.find('#q')
end

When(/^he enters an broker agency name and clicks on the search button$/) do
  page.fill_in('q', :with => "ACME Agency")
  page.find(:xpath, '//button[@type="submit"]').click
end

Then(/^he should see the one result with the agency name$/) do
  expect(page).to have_content("ACME Agency")
  expect(page).to have_no_content("Chase & Assoc")
end

Given(/^Hbx Admin click on (.*)$/) do |link_text|
  click_link(link_text)
end
