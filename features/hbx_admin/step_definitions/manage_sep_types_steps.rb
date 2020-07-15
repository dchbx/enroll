And(/^the user will see the Manage Sep Types tab$/) do
  find('.dropdown-toggle', :text => "Admin").click
  expect(page).to have_content('Manage Sep Types')
end

When("Admin clicks Manage Sep Types tab under admin dropdown") do
  page.find('.interaction-click-control-manage-sep-types').click
end

When("the Admin is navigated to the Manage Sep Types screen") do
  expect(page).to have_content('Manage Sep Types')
end

And(/^the Admin has the ability to use the following filters for documents provided: All, Individual, Shop and Congress$/) do
  expect(page).to have_xpath('//*[@id="Tab:all"]', text: 'All')
  expect(page).to have_xpath('//*[@id="Tab:ivl_qles"]', text: 'Individual')
  expect(page).to have_xpath('//*[@id="Tab:shop_qles"]', text: 'Shop')
  expect(page).to have_xpath('//*[@id="Tab:fehb_qles"]', text: 'Congress')
end

Then("Admin will click on the Sorting Sep Types button") do
  page.find('.interaction-click-control-sorting-sep-types').click
end