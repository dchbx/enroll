
Given(/^that the user is applying for a CONSUMER role$/) do
  visit "/users/sign_up"
  fill_in "user_oim_id", with: user_sign_up[:oim_id]
  fill_in "user_password", with: user_sign_up[:password]
  fill_in "user_password_confirmation", with: user_sign_up[:password_confirmation]
  click_button "Create account"
  create_plan
end

And(/the primary member has supplied mandatory information required$/) do
  visit privacy_insured_consumer_role_index_path
  expect(page).to have_content("Your Information")
  expect(page).to have_content("CONTINUE")
  click_link "CONTINUE"
  fill_in "person_first_name", with: personal_information[:first_name]
  fill_in "person_last_name", with: personal_information[:last_name]
  fill_in "jq_datepicker_ignore_person_dob", with: personal_information[:dob].to_s
  fill_in "person_ssn", with: personal_information[:ssn]
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  find('.btn', text: 'CONTINUE').click
  expect(page).to have_content('Thank you. Next, we need to verify if you or you and your family are eligible to enroll in coverage through DC Health Link. Please select CONTINUE.')
  find('.btn', text: 'CONTINUE').click
  find(:xpath, '//label[@for="person_us_citizen_true"]').click
  find(:xpath, '//label[@for="person_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  fill_in "person_addresses_attributes_0_address_1", with: personal_information[:address_1]
  fill_in "person_addresses_attributes_0_address_2", with: personal_information[:address_2]
  fill_in "person_addresses_attributes_0_city", with: personal_information[:city]
  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, '//*[@id="address_info"]/div/div[3]/div[2]/div/div[3]/div/ul/li[10]').click
  fill_in "person[addresses_attributes][0][zip]", with: personal_information[:zip]
  find('.btn', text: 'CONTINUE').click
end

Given(/^the primary member authorizes the system to call EXPERIAN$/) do
  expect(page).to have_content('Authorization and Consent')
  find(:xpath, '//label[@for="agreement_agree"]').click
  find('.btn', text: 'CONTINUE').click
end

Given(/^system receives a positive response from EXPERIAN$/) do
  expect(page).to have_content('Verify Identity')
end

Given(/^the user answers all VERIFY IDENTITY  questions$/) do 
  expect(page).to have_content('Verify Identity')
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
end

When(/^the user clicks submit$/) do
  click_button "Submit"
end

When(/^Experian returns a VERIFIED response$/) do
  click_link "Continue Application"
end

Then(/^The user will navigate to the Help Paying for Coverage page$/) do
  visit help_paying_coverage_financial_assistance_applications_path
end

Given(/^the user is on the Help Paying For Coverage page$/) do
  expect(page).to have_content('Help Paying for Coverage')
end

When(/^the user clicks CONTINUE$/) do
  find('.interaction-click-control-continue').trigger('click')
end

When(/^the answer to Do you want to apply for Medicaid… is NIL$/) do
  expect(find('#radio1', visible: false)).not_to be_checked
  expect(find('#radio2', visible: false)).not_to be_checked
end

Then(/^the user will remain on the page$/) do
  expect(page).to have_content('Do you want to apply for Medicaid, tax credits, savings and cost-sharing reductions ? *')
end

Then(/^an error message will display stating the requirement to populate an answer$/) do
  expect(page).to have_content('Please choose an option before you proceed.')
end

When(/^the answer to Do you want to apply for Medicaid… is NO$/) do
  find(:xpath, '//label[@for="radio2"]').click
end

When(/^clicks CONTINUE$/) do
  find('.btn', text: 'CONTINUE').click
end

Then(/^the user will navigate to the UQHP Household Info: Family Members page$/) do
  consumer.person.families.last.family_members.each do |family_member|
    expect(page).to have_content(family_member.first_name)
  end
end

When(/^the answer to Do you want to apply for Medicaid… is YES$/) do
  find(:xpath, '//label[@for="radio1"]').click
end

Then(/^the user will navigate to the FAA Household Info: Family Members page$/) do
  consumer.person.families.last.family_members.each do |family_member|
    expect(page).to have_content(family_member.first_name)
  end
  expect(page).to have_content('Household Info: Family Members')
end

When(/^the user clicks the PREVIOUS link$/) do
  find('.interaction-click-control-previous').trigger 'click'
end

When(/^navigates to the Verify Identity page$/) do
  visit new_insured_interactive_identity_verification_path
  expect(page).to have_content('Verify Identity')
end

When(/^the user clicks the SAVE & EXIT link$/) do
  find('.interaction-click-control-save---exit').trigger 'click'
end

Then(/^next time the user logs in the user will Help Paying For Coverage page$/) do
  visit "/users/sign_in"
  fill_in "user_login", with: user_sign_up[:oim_id]
  fill_in "user_password", with: user_sign_up[:password]
  click_button "Sign in"
end

Then(/^saves a YES answer to the question: Do you want to apply for Medicaid…$/) do
  find(:xpath, '//label[@for="radio1"]').click
  find('.btn', text: 'CONTINUE').click
end

Given(/^that the user is on the Application Checklist page$/) do
  visit application_checklist_financial_assistance_applications_path
end

Then(/^the user will navigate to the FAA Household Infor: Family Members page$/) do
  expect(page).to have_content('Household Info: Family Members')
end

Then(/^the next time the user logs in the user will see Application checklist page$/) do
  visit "/users/sign_in"
  fill_in "user_login", with: user_sign_up[:oim_id]
  fill_in "user_password", with: user_sign_up[:password]
  click_button "Sign in"
end
