# frozen_string_literal: true

Given(/^Admin is on the new Bulk Notice view$/) do
  visit new_exchanges_bulk_notice_path
end

When(/^Admin selects Employer$/) do
  select 'Employer'
end

When(/^Admin fills form with ACME FEIN$/) do
  fill_in "bulk-notice-audience-identifiers", with: employer("ACME").fein
  find("body").click
end

Then(/^Admin should see ACME badge$/) do
  expect(page).to have_css('span.badge', text: employer("ACME").hbx_id)
end

When(/^Admin fills in the rest of the form$/) do
  fill_in "admin_bulk_notice_subject", with: "Subject"
  fill_in "admin_bulk_notice_body", with: "Other Content"
end

When(/^Admin clicks on Preview button$/) do
  click_on 'Preview'
end

Then(/^Admin should see the Preview Screen$/) do
  expect(page).to have_content('Preview')
end
