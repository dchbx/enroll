Given(/^the Family Relationships link displays in the left column of the page$/) do
  expect(page).to have_content('Family Relationships')
end

Then(/^the Family Relationships link is disabled$/) do
  page.should have_no_link('Family Relationships')
end

Given(/^the Family Relationships link is enabled$/) do
  page.should have_link('Family Relationships')
end

When(/^the user clicks the Family Relationships link$/) do
  find(:xpath,'//*[@id="left-navigation"]/li[3]/a').click
end

Then(/^the user will navigate to the Family relationships page$/) do
  expect(page).to have_content('Family Relationships')
  expect(page).to have_content('HOUSEHOLD MEMBER')
end

