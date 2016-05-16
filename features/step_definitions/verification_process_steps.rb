module VerificationUser
  def user(*traits)
    attributes = traits.extract_options!
    @user ||= FactoryGirl.create :user, *traits, attributes
  end
end
World(VerificationUser)

Then(/^Individual click continue button$/) do
  click_button "CONTINUE"
end

Then(/^I should see verification outstanding label$/) do
  expect(page).to have_content "Action Needed"
end

When(/^I click on verification link$/) do
  click_link "Documents"
end

Given(/^I should see page for documents verification$/) do
  expect(page).to have_content "Documents FAQ"
  expect(page).to have_selector('table tr')
end

Given(/^I upload the file as vlp document$/) do
  within('div.Number') do
    attach_file('file[]', Rails.root.join('app', 'assets', 'images', 'logo', 'carefirst.jpg'))
  end
end

Given(/^I click the upload file button$/) do
  within('div.Number2') do
    click_button "Upload"
  end
end

Given(/^a consumer exists$/) do
  user :with_consumer_role
end

Given(/^the consumer is logged in$/) do
  login_as user

end

When(/^the consumer visits verification page$/) do
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



