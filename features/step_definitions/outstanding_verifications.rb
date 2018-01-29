Given(/^oustanding verfications users exists$/) do
  person = FactoryGirl.create(:person, :with_consumer_role)
  @person_name = person.full_name
  family = FactoryGirl.create(:family, :with_primary_family_member, person: person)
  enrollment = FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: family.active_household, aasm_state: "enrolled_contingent", kind: "individual", effective_on: TimeKeeper.date_of_record.beginning_of_year)
  families = Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent")
end

When(/^Admin clicks Outstanding Verifications$/) do
  page.find('.families.dropdown-toggle.interaction-click-control-families').click
  page.find('.interaction-click-control-outstanding-verifications').click
end

Then(/^the Admin is navigated to the Outstanding Verifications screen$/) do
  expect(page).to have_xpath("//div[contains(@class, 'container')]/h1", text: 'Outstanding Verifications')
end


Then(/^the Admin has the ability to use the following filters for documents provided: Fully Uploaded, Partially Uploaded, None Uploaded, All$/) do
  expect(page).to have_xpath('//*[@id="Tab:vlp_partially_uploaded"]', text: 'Partially Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:vlp_fully_uploaded"]', text: 'Fully Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:vlp_none_uploaded"]', text: 'None Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:all"]', text: 'All')
end

Then(/^the Admin is directed to that user's My DC Health Link page$/) do
  page.find(:xpath, "//table[contains(@class, 'effective-datatable')]/tbody/tr/td[1]/a").trigger('click')
  expect(page).to have_content("My DC Health Link")
  expect(page).to have_content("#{@person_name}")
end

