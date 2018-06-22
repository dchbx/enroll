module VerificationUser
  def user(*traits)
    attributes = traits.extract_options!
    @user ||= FactoryGirl.create :user, *traits, attributes
  end
end
World(VerificationUser)

Then(/^Individual click continue button$/) do
  find('.btn', text: 'CONTINUE').click
end

Then(/^I should see Documents link$/) do
  expect(page).to have_content "Documents"
end

When(/^I click on verification link$/) do
  click_link "Documents"
end

Given(/^I should see page for documents verification$/) do
  expect(page).to have_content "Documents FAQ"
  expect(page).to have_content('Social Security Number')
  find('.btn', text: 'Documents FAQ').click
  expect(page).to have_content('DC Residency')
  find_link('https://dmv.dc.gov/page/proof-dc-residency-certifications').visible?
  new_window = window_opened_by { click_link 'https://dmv.dc.gov/page/proof-dc-residency-certifications' }
  switch_to_window new_window
end

Given(/^a consumer exists$/) do
  user :with_consumer_role
end

Given(/^the consumer is logged in$/) do
  login_as user
end

Then(/^the consumer visits verification page$/) do
  visit verification_insured_families_path
  find(:xpath, "//ul/li/a[contains(@class, 'interaction-click-control-documents')]").click
end

When(/^the consumer should see documents verification page$/) do
  expect(page).to have_content('We verify the information you give us using electronic data sources. If the data sources do not match the information you gave us, we need you to provide documents to prove what you told us.')
  expect(page).to have_content "Documents FAQ"
  expect(page).to have_content('Social Security Number')
end

When(/^the consumer is completely verified$/) do
  user.person.consumer_role.import!(OpenStruct.new({:determined_at => Time.now, :vlp_authority => "hbx"}))
end

When(/^the consumer is completely verified from curam$/) do
  user.person.consumer_role.import!
  user.person.consumer_role.update_attributes(vlp_authority: 'curam', aasm_state: 'fully_verified')
end

Then(/^verification types have to be visible$/) do
  expect(page).to have_content('Social Security Number')
  expect(page).to have_content('Citizenship')
end

Then(/^verification types should display as verified state$/) do
  expect(page).to have_content('Social Security Number')
  expect(page).to have_content('Citizenship')
  expect(page).to have_content('Verified')
end

Then(/^verification types should display as external source$/) do
  expect(page).to have_content('Social Security Number')
  expect(page).to have_content('Citizenship')
  expect(page).to have_content('External Source')
end

Given(/^consumer has outstanding verification and unverified enrollments$/) do
  family = user.person.primary_family
  enr = FactoryGirl.create(:hbx_enrollment,
                           household: family.active_household,
                           coverage_kind: "health",
                           effective_on: TimeKeeper.date_of_record - 2.months,
                           enrollment_kind: "open_enrollment",
                           kind: "individual",
                           submitted_at: TimeKeeper.date_of_record - 2.months,
                           special_verification_period: TimeKeeper.date_of_record - 20.days)
  enr.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: family.active_family_members[0].id,
                                                        eligibility_date: TimeKeeper.date_of_record - 2.months,
                                                        coverage_start_on: TimeKeeper.date_of_record - 2.months)
  enr.save!
  family.enrollments.first.move_to_contingent!
  family.active_family_members.first.person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
end

Then(/^consumer should see Verification Due date label$/) do
  expect(page).to have_content('Document Due Date:')
end

Then(/^consumer should see Documents FAQ link$/) do
  expect(page).to have_content('Documents FAQ')
end
