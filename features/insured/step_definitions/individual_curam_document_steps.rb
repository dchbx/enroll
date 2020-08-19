
When(/^the user navigates to the DOCUMENTS tab$/) do
  visit verification_insured_families_path
end

Then(/^a button will be visible to the user labeled GO TO MEDICAID$/) do
  expect(page).to have_content('Go To Medicaid')
end

When(/^GO TO MEDICAID button is visible to the user$/) do
  find_link('Go to Medicaid').visible?
end

Then(/^there will be text to the left of the GO TO MEDICAID button$/) do
  expect(page).to have_content('If you qualify for Medicaid, view your Medicaid documents.')
end

Then(/^there will be messages text to the left of the GO TO MEDICAID button$/) do
  expect(page).to have_content('If you qualify for Medicaid, view your Medicaid messages.')
end

When(/^the user clicks on the GO TO MEDICAID button$/) do
  switch_to_window { find('.btn', text: 'Go To Medicaid').click }
end

Then(/^EA sets a flag in IAM to direct the consumer to the curam\/ drupal login$/) do
  expect(page).to have_content('info@dchealthlink.com')
end

When(/^selects a Person account and navigates to Verification page$/) do
  @person = FactoryGirl.create(:person, :with_consumer_role)
  visit verification_insured_families_path
end

When(/^the broker visits verification page$/) do
  visit verification_insured_families_path
end

When(/^the user visits messages page$/) do
  visit inbox_insured_families_path
end

When(/^selects a Person account and navigates to Messages page$/) do
  @person = FactoryGirl.create(:person, :with_consumer_role)
  visit inbox_insured_families_path
end