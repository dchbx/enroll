And(/^the user will see the Manage Sep Types under admin dropdown$/) do
  find('.dropdown-toggle', :text => "Admin").click
  expect(page).to have_content('Manage Sep Types')
end

When("Admin clicks Manage Sep Types") do
  page.find('.interaction-click-control-manage-sep-types').click
end

Given("the Admin is navigated to the Manage Sep Types screen") do
  expect(page).to have_content('Manage Sep Types')
end

And(/^the Admin has the ability to use the following filters for documents provided: All, Individual, Shop and Congress$/) do
  expect(page).to have_xpath('//*[@id="Tab:all"]', text: 'All')
  expect(page).to have_xpath('//*[@id="Tab:ivl_qles"]', text: 'Individual')
  expect(page).to have_xpath('//*[@id="Tab:shop_qles"]', text: 'Shop')
  expect(page).to have_xpath('//*[@id="Tab:fehb_qles"]', text: 'Congress')
end

Given(/^Qualifying life events of all markets are present$/) do
  step "Qualifying life events are present"
  fehb_qle = FactoryBot.create(:qualifying_life_event_kind, title: 'Covid-19', reason: 'covid-19', market_kind: "fehb", post_event_sep_in_days: 30,  effective_on_kinds: ["first_of_this_month", "fixed_first_of_next_month"], ordinal_position: 1, qle_event_date_kind: :submitted_at)
  ivl_qles = [:effective_on_event_date, :effective_on_first_of_month, :effective_on_fixed_first_of_next_month].map { |event_trait| FactoryBot.create(:qualifying_life_event_kind, event_trait, market_kind: "individual", post_event_sep_in_days: 90)}
end

When("Admin will click on the Sorting Sep Types button") do
  page.find('.interaction-click-control-sorting-sep-types').click
end

Then(/^Admin will see three tabs Individual, Shop and Congress markets$/) do
  expect(page).to have_content('Individual')
  expect(page).to have_content('Shop')
  expect(page).to have_content('Congress')
end

And(/^Admin will sort Individual market sep types$/) do
  k = find("#marriage_individual")
  l = find("#birth_individual")
  k.drag_to(l)
end

Then(/^Admin should see successful message after sorting$/) do
  expect(page).to have_content('Successfully sorted')
end
