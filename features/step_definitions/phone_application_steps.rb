And(/^admin has navigated into the NEW CONSUMER APPLICATION$/) do
	visit exchanges_hbx_profiles_root_path
	click_link "Families"
	page.find('.interaction-click-control-new-consumer-application').click
	visit begin_consumer_enrollment_exchanges_agents_path
end

And(/^the Admin is on the Personal Info page for the family$/) do
	fill_in "person_first_name", with: "John"
  fill_in "person_last_name", with: "Smith"
  fill_in "jq_datepicker_ignore_person_dob", with: "11/11/1991"
  fill_in "person_ssn", with: '212-31-3131'
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  find('.btn', text: 'CONTINUE').click

  expect(page).to have_content('Thank you. Next, we need to verify if you or you and your family are eligible to enroll in coverage through DC Health Link. Please select CONTINUE.')
  find('.btn', text: 'CONTINUE').click
end

And(/^the Admin clicks the Application Type drop down$/) do
	find(:xpath, "//p[@class='label'][contains(., 'choose')]").click 
end

And(/^the Admin selects the Phone application option$/) do
  find(:xpath, '/html/body/div[2]/form/div[1]/div/div/div/div/div[2]/div/div/div[3]/div/ul/li[2]').click
end

Given(/^all other mandatory fields on the page have been populated$/) do
	find(:xpath, '//label[@for="person_us_citizen_true"]').click
  find(:xpath, '//label[@for="person_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  fill_in "person_addresses_attributes_0_address_1", with: "123 Main St"
  fill_in "person_addresses_attributes_0_address_2", with: "apt 1005"
  fill_in "person_addresses_attributes_0_city", with: "Washington"
  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, '//*[@id="address_info"]/div/div[3]/div[2]/div/div[3]/div/ul/li[10]').click
  fill_in "person[addresses_attributes][0][zip]", with: "35465"
end

When(/^Admin clicks CONTINUE button$/) do
  find('.btn', text: 'CONTINUE').click
end

Then(/^the Admin should navigate to the Experian Auth and Consent Page$/) do
	visit '/insured/consumer_role/ridp_agreement'
end

When(/^the Admin chooses 'I Disagree'$/) do
	find(:xpath, '//label[@for="agreement_disagree"]').click
end

Then(/^the Admin will be navigated to the DOCUMENT UPLOAD page$/) do
	visit '/insured/consumer_role/upload_ridp_document'
end

When(/^the Admin clicks CONTINUE without uploading and verifying an application$/) do
	find(:xpath, '//*[@id="btn-continue"]').trigger('click')
end

Then(/^the Admin can not navigate to the next page$/) do
	find('.interaction-click-control-continue')['disabled'].should == "disabled"
end

When(/^the Admin clicks CONTINUE after uploading and verifying an application$/) do
  find('#upload_identity').click
  find('#select_upload_identity').click
  within '#select_upload_identity' do
    attach_file("file[]", "#{Rails.root}/lib/pdf_templates/blank.pdf", visible:false)
  end
  wait_for_ajax(10,2)

  find(:xpath, "/html/body/div[2]/div[3]/div/div/div[1]/div[2]/div/div/div/div[2]/div[1]/div/div[4]/div/div[2]").click
  find('.interaction-choice-control-verification-reason-1').click
  find('.interaction-choice-control-verification-reason', :text => /\ASelect Reason\z/).click
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click

  find(:xpath, "/html/body/div[2]/div[3]/div/div/div[1]/div[2]/div/div/div/div[2]/div[5]/div/div[4]/div/div[2]").click
  find('.interaction-choice-control-verification-reason-1').click
  find('.interaction-choice-control-verification-reason', :text => /\ASelect Reason\z/).click
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click

  expect(page).to have_content('Application successfully verified.')
  find('.btn', text: 'CONTINUE').click
end

Then(/^the Admin can navigate to the next page and finish the application$/) do
  expect(page).to have_content('Household Info: Family Members')
end
