# frozen_string_literal: true

When(/^the user navigates to the DOCUMENTS tab$/) do
  visit verification_insured_families_path
end

Then(/^a button will be visible to the user labeled MEDICAID & TAX CREDITS$/) do
  expect(page).to have_content('Medicaid & Tax Credits')
end

When(/^MEDICAID & TAX CREDITS button is visible to the user$/) do
  find_link('Medicaid & Tax Credits').visible?
end

Then(/^there will be text to the left of the MEDICAID & TAX CREDITS button$/) do
  expect(page).to have_content('If you applied for Medicaid and tax credit savings, view additional documents')
end

Then(/^there will be messages text to the left of the MEDICAID & TAX CREDITS button$/) do
  expect(page).to have_content('If you applied for Medicaid and tax credit savings, view additional messages')
end

When(/^the user clicks on the MEDICAID & TAX CREDITS button$/) do
  switch_to_window { find('.btn', text: 'Medicaid & Tax Credits').click }
end

Then(%r{^EA sets a flag in IAM to direct the consumer to the curam/ drupal login$}) do
  expect(page).to have_content('info@dchealthlink.com')
end

When(/^selects a Person account and navigates to Verification page$/) do
  @person = FactoryBot.create(:person, :with_consumer_role)
  visit verification_insured_families_path
end

When(/^the broker visits verification page$/) do
  visit verification_insured_families_path
end

When(/^the user visits messages page$/) do
  visit inbox_insured_families_path
end

When(/^selects a Person account and navigates to Messages page$/) do
  @person = FactoryBot.create(:person, :with_consumer_role)
  visit inbox_insured_families_path
end
