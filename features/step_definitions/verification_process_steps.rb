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
