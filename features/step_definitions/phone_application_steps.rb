# frozen_string_literal: true

And(/^admin has navigated into the NEW CONSUMER APPLICATION$/) do
  visit exchanges_hbx_profiles_root_path
  find('.interaction-click-control-families', wait: 10).click
  page.find('.interaction-click-control-new-consumer-application', wait: 10).click
  visit begin_consumer_enrollment_exchanges_agents_path
end

And(/^the Admin is on the Personal Info page for the family$/) do
  fill_in "person_first_name", with: "John"
  fill_in "person_last_name", with: "Smith"
  fill_in "jq_datepicker_ignore_person_dob", with: "11/11/1991"
  fill_in "person_ssn", with: '212-31-3131'
  find(:xpath, '//label[@for="radio_male"]', wait: 10).click
  find('.btn', text: 'CONTINUE', wait: 10).click

  expect(page).to have_content('Next, we need to verify if you or you and your family are eligible to enroll in coverage through DC Health Link. Select CONTINUE.')
  find('.interaction-click-control-continue', wait: 10).click
end

And(/^the Admin clicks the Application Type drop down$/) do
  find('span.label', text: 'choose *', wait: 10).click
end

And(/^the Admin selects the Phone application option$/) do
  find(".interaction-choice-control-application-type-id-1", wait: 10)
end

Given(/^all other mandatory fields on the page have been populated$/) do
  step 'person selects all mandatory radio option for us citizen'
  find(:xpath, '//label[@for="radio_incarcerated_no"]', wait: 10).click
  fill_in "person_addresses_attributes_0_address_1", with: "123 Main St"
  fill_in "person_addresses_attributes_0_address_2", with: "apt 1005"
  fill_in "person_addresses_attributes_0_city", with: "Washington"
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]", wait: 10).click
  find(:xpath, '//*[@id="address_info"]/div/div[3]/div[2]/div/div[3]/div/ul/li[10]', wait: 10).click
  fill_in "person[addresses_attributes][0][zip]", with: "35465"
end

And(/^person selects all mandatory radio option for us citizen$/) do
  find(:xpath, '//label[@for="person_us_citizen_true"]', wait: 10).click
  find(:xpath, '//label[@for="person_naturalized_citizen_false"]', wait: 10).click
  find(:xpath, '//label[@for="indian_tribe_member_no"]', wait: 10).click
end

And('person goes to the next pages') do
  step "Admin clicks CONTINUE button"
  step "Individual agrees to the privacy agreeement"
  step "Individual should see identity verification page and clicks on submit"
  step "I click on continue button on household info form"
end

When(/^Admin clicks CONTINUE button$/) do
  find('.btn', text: 'CONTINUE', wait: 10).click
end

When(/^Admin clicks Continue button$/) do
  find('.button', text: 'Continue', wait: 10).click
end

Then(/^the Admin should navigate to the Experian Auth and Consent Page$/) do
  visit '/insured/consumer_role/ridp_agreement'
end

When(/^the Admin chooses 'I Disagree'$/) do
  find(:xpath, '//label[@for="agreement_disagree"]', wait: 10).click
end

Then(/^the Admin will be navigated to the DOCUMENT UPLOAD page$/) do
  visit '/insured/consumer_role/upload_ridp_document'
end

When(/^the Admin clicks CONTINUE without uploading and verifying an application$/) do
  find(:xpath, '//*[@id="btn-continue"]', wait: 10).trigger('click')
end

Then(/^the Admin can not navigate to the next page$/) do
  find('.interaction-click-control-continue')['disabled'].should == "disabled"
end

When(/^the Admin clicks CONTINUE after uploading and verifying an application$/) do
  find('#upload_application')
  within '#upload_application' do
    attach_file('file[]', "#{Rails.root}/lib/pdf_templates/blank.pdf", visible: false)
  end
  wait_for_ajax(10, 2)
  within('#Application') do
    find('.label', :text => "Action", wait: 10).click
    find('li', :text => 'Verify', wait: 10).click
  end

  wait_for_ajax(10, 2)
  find('.verification-update-reason').click
  find('li', :text => 'Document in EnrollApp', wait: 10).click
  find('.v-type-confirm-button', wait: 10).click
  expect(page).to have_content('Application successfully verified.')
  find('.button', text: 'CONTINUE', wait: 10).click
end

Then(/^the Admin can navigate to the next page and finish the application$/) do
  expect(page).to have_content(l10n('family_information').to_s)
end
