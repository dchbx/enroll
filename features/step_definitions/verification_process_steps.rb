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
  expect(page).to have_selector('table tr')
end

Given(/^I upload the file as vlp document$/) do
  script = "$('[name=\"file[]\"]').css({opacity: 100, display: 'block'});"
  page.evaluate_script(script)
  within('div.Number') do
    attach_file('file[]', Rails.root.join('app', 'assets', 'images', 'logo', 'carrier' ,'carefirst.jpg'))
  end
end

Given(/^I click the upload file button$/) do
  within first('div.btn-group') do
    click_button "Upload", :match => :first
  end
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
  expect(page).to have_content "Documents FAQ"
  expect(page).to have_selector('table tr')
end

Then(/^the consumer can expand the table by clicking on caret sign$/) do
  find('.fa-caret-down').click
end

When(/^the consumer is completely verified$/) do
  user.person.consumer_role.import!(OpenStruct.new({:determined_at => Time.now, :vlp_authority => "hbx"}))
end

Then(/^verification types have to be visible$/) do
  expect(page).to have_content('Social Security Number')
  expect(page).to have_content('Citizenship')
end

Given(/^consumer has outstanding verification and unverified enrollments$/) do
  family = user.person.primary_family
  FactoryGirl.create(:hbx_enrollment,
                     household: family.active_household,
                     coverage_kind: "health",
                     effective_on: TimeKeeper.date_of_record - 2.months,
                     enrollment_kind: "open_enrollment",
                     kind: "individual",
                     submitted_at: TimeKeeper.date_of_record - 2.months,
                     special_verification_period: TimeKeeper.date_of_record - 20.days)
  family.enrollments.first.move_to_contingent!
  family.active_family_members.first.person.consumer_role.aasm_state = "verification_outstanding"
  family.active_family_members.first.person.save!
end

Then(/^consumer should see Verification Due date label$/) do
  expect(page).to have_content('Document Due Date:')
end

Then(/^consumer should see Documents FAQ link$/) do
  expect(page).to have_content('Documents FAQ')
end