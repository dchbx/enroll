# frozen_string_literal: true

Then(/^Hbx Admin should see search box$/) do
  wait_for_ajax
  page.find("input[type='search']").visible?
end

When(/^he enters an broker agency name and clicks on the search button$/) do
  page.find("input[type='search']").set(broker_agency_profile.legal_name)
end

Then(/^he should see the one result with the agency name$/) do
  wait_for_ajax
  expect(page).to have_content(broker_agency_profile.legal_name)
end