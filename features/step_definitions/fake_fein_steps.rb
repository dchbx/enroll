# frozen_string_literal: true

Then(/^.+ should not see fein$/) do
  expect(page).not_to have_content("Fein")
end

Then(/^.+ should see fein$/) do
  expect(page).to have_content("Fein")
end

Then(/^.+ clicks on the broker$/) do
  broker_organization_legal_name = broker_organization.legal_name
  click_link broker_organization_legal_name
end

When(/^Hbx Admin clicks on the Fake broker$/) do
  click_link "Logistics Inc"
end
