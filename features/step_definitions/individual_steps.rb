When(/^\w+ visits? the Insured portal during open enrollment$/) do
  visit "/"
  click_link 'Consumer/Family Portal'
  FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period)
  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "individual")

  Caches::PlanDetails.load_record_cache!
  screenshot("individual_start")
end

When(/^\w+ visits? the Insured portal outside of open enrollment$/) do
  FactoryGirl.create(:hbx_profile, :no_open_enrollment_coverage_period)
  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "individual")
  Caches::PlanDetails.load_record_cache!

  visit "/"
  click_link 'Consumer/Family Portal'
  screenshot("individual_start")
end

And(/Individual asks how to make an email account$/) do

  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.a(text: /Don't have an email account?/).fire_event("onclick")
  @browser.element(class: /modal/).wait_until_present
  @browser.element(class: /interaction-click-control-×/).fire_event("onclick")
end

Then(/Individual creates HBX account$/) do
  click_button 'Create account', :wait => 10
  fill_in "user[oim_id]", :with => (@u.email :email)
  fill_in "user[password]", :with => "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", :with => "aA1!aA1!aA1!"
  screenshot("create_account")
  click_button "Create account"
end

And(/user should see your information page$/) do
  expect(page).to have_content("Your Information")
  expect(page).to have_content("CONTINUE")
  click_link "CONTINUE"
end

When(/user goes to register as an individual$/) do
  fill_in 'person[first_name]', :with => (@u.first_name :first_name)
  fill_in 'person[last_name]', :with => (@u.last_name :last_name)
  fill_in 'jq_datepicker_ignore_person[dob]', :with => (@u.adult_dob :adult_dob)
  fill_in 'person[ssn]', :with => (@u.ssn :ssn)
  find(:xpath, '//label[@for="radio_male"]').click

  screenshot("register")
  find('.btn', text: 'CONTINUE').click
end

When(/^\w+ clicks? on continue button$/) do
  wait_for_ajax
  click_link "Continue"
end

Then(/^user should see heading labeled personal information/) do
  expect(page).to have_content("Personal Information")
end

Then(/Individual should click on Individual market for plan shopping/) do
  wait_for_ajax
  expect(page).to have_button("CONTINUE", visible: false)
  find('.btn', text: 'CONTINUE').click
end

Then(/Individual should see a form to enter personal information$/) do
  find(:xpath, '//label[@for="person_us_citizen_true"]').click
  find(:xpath, '//label[@for="person_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click

  find(:xpath, '//label[@for="radio_incarcerated_no"]').click

  fill_in "person_addresses_attributes_0_address_1", :with => "4900 USAA BLVD"
  fill_in "person_addresses_attributes_0_address_2", :with => "212"
  fill_in "person_addresses_attributes_0_city", :with=> "Washington"
  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, '//*[@id="address_info"]/div/div[3]/div[2]/div/div[3]/div/ul/li[10]').click
  fill_in "person[addresses_attributes][0][zip]", :with => "20002"
  fill_in "person[phones_attributes][0][full_phone_number]", :with => "9999999999"
  screenshot("personal_form")
end

When(/Individual clicks on Save and Exit/) do
  find('li a', text: 'SAVE & EXIT').trigger('click')
end

Then (/Individual resumes enrollment/) do
  visit '/'
  click_link 'Consumer/Family Portal'
end

Then (/Individual sees previously saved address/) do
  expect(page).to have_field('ADDRESS LINE 1 *', with: '4900 USAA BLVD')
  find('.btn', text: 'CONTINUE').click
end

When /^Individual clicks on Individual and Family link should be on privacy agreeement page/ do
  wait_for_ajax
  find('.interaction-click-control-individual-and-family').trigger('click')
  expect(page).to have_content('Authorization and Consent')
end

Then(/^\w+ agrees? to the privacy agreeement/) do
  expect(page).to have_content('Authorization and Consent')
  find(:xpath, '//label[@for="agreement_agree"]').click
  click_link "Continue"
end

When /^Individual clicks on Individual and Family link should be on verification page/ do
  wait_for_ajax
  find('.interaction-click-control-individual-and-family').trigger('click')
  expect(page).to have_content('Verify Identity')
end

Then(/^\w+ should see identity verification page and clicks on submit/) do
  expect(page).to have_content('Verify Identity')
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
  screenshot("identify_verification")
  click_button "Submit"
  screenshot("override")
  click_link "Please click here once you have contacted the exchange and have been told to proceed."
end

Then(/\w+ should see the dependents form/) do
  expect(page).to have_content('Add Member')
  screenshot("dependents")
end

And(/Individual clicks on add member button/) do
  find(:xpath, '//*[@id="dependent_buttons"]/div/a').click
  expect(page).to have_content('Lives with primary subscriber')

  fill_in "dependent[first_name]", :with => @u.first_name
  fill_in "dependent[last_name]", :with => @u.last_name
  fill_in "jq_datepicker_ignore_dependent[dob]", :with => @u.adult_dob
  fill_in "dependent[ssn]", :with => @u.ssn
  find(:xpath, "//p[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div[1]/div[3]/div/ul/li[3]').click
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  screenshot("add_member")
  all(:css, ".mz").last.click
end

And(/Individual again clicks on add member button/) do
  find(:xpath, '//*[@id="dependent_buttons"]/div/a').click
  expect(page).to have_content('Lives with primary subscriber')

  fill_in "dependent[first_name]", :with => @u.first_name
  fill_in "dependent[last_name]", :with => @u.last_name
  fill_in "jq_datepicker_ignore_dependent[dob]", :with => '01/15/2013'
  fill_in "dependent[ssn]", :with => @u.ssn
  find(:xpath, "//p[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div[1]/div[3]/div/ul/li[4]').click
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click

  #testing
  screenshot("added member")
  all(:css, ".mz").last.click
end


And(/I click on continue button on household info form/) do
  screenshot("line 161")
  click_link "Continue"
end

Then(/Individual creates a new HBX account$/) do
  click_button 'Create account', :wait => 10
  fill_in "user[oim_id]", :with => "testflow@test.com"
  fill_in "user[password]", :with => "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", :with => "aA1!aA1!aA1!"
  screenshot("create_account")
  click_button "Create account"
end

When(/I click on none of the situations listed above apply checkbox$/) do
  expect(page).to have_content 'None of the situations listed above apply'
  find('#no_qle_checkbox').click
  expect(page).to have_content 'To enroll before open enrollment'
end

And(/I click on back to my account button$/) do
  expect(page).to have_content "To enroll before open enrollment, you must qualify for a special enrollment period"
  find('.interaction-click-control-back-to-my-account').click
end

Then(/I should land on home page$/) do
  expect(page).to have_content 'My DC Health Link'
end

And(/I click on log out link$/) do
  find('.interaction-click-control-logout').click
end

And(/I click on sign in existing account$/) do
  expect(page).to have_content "Welcome to the District's Health Insurance Marketplace"
  find('.interaction-click-control-sign-in-existing-account').click
end

And(/I signed in$/) do
  fill_in "user[login]", :with => "testflow@test.com"
  fill_in "user[password]", :with => "aA1!aA1!aA1!"
  click_button 'Sign in'
end


When(/^I click on continue button on group selection page during a sep$/) do
  expect(page).to have_content "Choose Coverage for your Household"
  click_button "CONTINUE"
end

Then(/I click on back to my account$/) do
  expect(page).to have_content "Choose Coverage for your Household"
  find('.interaction-click-control-back-to-my-account').click
end

And(/^I click on continue button on group selection page$/) do
  #TODO This some group selection nonsense
  #wait_for_ajax(2,2)
  screenshot("test1")
  #click_link "Continue" #Get
  click_button "CONTINUE"
  screenshot("test2")
  wait_for_ajax
  find(:xpath, '//*[@id="btn-continue"]').trigger('click')
  #click_button "Continue" #Post
  screenshot("test3")
  #Goes off the see the wizard at /I select three plans to compare/ for now
end

And(/I select a plan on plan shopping page/) do
   screenshot("plan_shopping")
   find(:xpath, '//*[@id="plans"]/div[1]/div/div[5]/div[3]/a[1]').click
end

And(/I click on purchase button on confirmation page/) do
  find('.interaction-choice-control-value-terms-check-thank-you').click
  fill_in 'first_name_thank_you', :with => (@u.find :first_name)
  fill_in 'last_name_thank_you', :with => (@u.find :last_name)
  screenshot("purchase")
  click_link "Confirm"
end

And(/I click on continue button to go to the individual home page/) do
  click_link "GO TO MY ACCOUNT"
end

And(/I should see the individual home page/) do
  expect(page).to have_content "My #{Settings.site.short_name}"
  screenshot("my_account")
  # something funky about these tabs in JS
  # click_link "Documents"
  # click_link "Manage Family"
  # click_link "My #{Settings.site.short_name}"
end

Then(/^Individual edits a dependents address$/) do
  click_link 'Add Member'
end

Then(/^Individual fills in the form$/) do
  fill_in 'dependent[first_name]', :with => (@u.first_name :first_name)
  fill_in 'dependent[last_name]', :with => (@u.last_name :last_name)
  fill_in 'jq_datepicker_ignore_dependent[dob]', :with => (@u.adult_dob :dob)
  fill_in 'dependent[ssn]', :with => (@u.ssn :ssn)
  find('.house .selectric p.label').trigger 'click'
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Sibling')]").click
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
end

Then(/^Individual ads address for dependent$/) do
  find(:xpath, '//label[@for="dependent_same_with_primary"]').click
  fill_in 'dependent[addresses][0][address_1]', :with => '36 Campus Lane'
  fill_in 'dependent[addresses][0][city]', :with => 'Washington'
  find('#address_info .selectric p.label').trigger 'click'
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'DC')]").click
  fill_in 'dependent[addresses][0][zip]', :with => "20002"
  all(:css, ".mz").last.click
  find('#btn-continue').click
end

And(/I click to see my Secure Purchase Confirmation/) do
  wait_and_confirm_text /Messages/
  @browser.link(text: /Messages/).click
  wait_and_confirm_text /Your Secure Enrollment Confirmation/
end

When(/^I visit the Insured portal$/) do
  visit "/"
  click_link 'Consumer/Family Portal'
end

Then(/Second user creates an individual account$/) do
  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@u.email :email2)
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).set("aA1!aA1!aA1!")
  screenshot("create_account")
  scroll_then_click(@browser.input(value: "Create account"))
end

Then(/^Second user goes to register as individual/) do
  step "user should see your information page"
  step "user goes to register as an individual"
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Second")
  @browser.text_field(class: /interaction-field-control-person-ssn/).set(@u.ssn :ssn2)
end

Then(/^Second user should see a form to enter personal information$/) do
  step "Individual should see a form to enter personal information"
  @browser.text_field(class: /interaction-field-control-person-emails-attributes-0-address/).set(@u.email :email2)
end

Then(/Individual asks for help$/) do
  expect(page).to have_content "Help"
  find('.container .row div div.btn', text: 'Help').click
  wait_for_ajax
  expect(page).to have_content "Help"
  click_link "Help from a Customer Service Representative"
  wait_for_ajax(5,2.5)
  expect(page).to have_content "First name"
  #TODO bombs on help_first_name sometimes
  fill_in "help_first_name", with: "Sherry"
  fill_in "help_last_name", with: "Buckner"
  screenshot("help_from_a_csr")
  find("#search_for_plan_shopping_help").click
  find(".interaction-click-control-×").click
end

And(/^.+ clicks? the continue button$/i) do
  click_when_present(@browser.a(text: /continue/i))
end

Then(/^.+ sees the Verify Identity Consent page/)  do
  wait_and_confirm_text(/Verify Identity/)
end

When(/^a CSR exists/) do
  p = FactoryGirl.create(:person, :with_csr_role, first_name: "Sherry", last_name: "Buckner")
  sleep 2 # Need to wait on factory
  FactoryGirl.create(:user, email: "sherry.buckner@dc.gov", password: "aA1!aA1!aA1!", password_confirmation: "aA1!aA1!aA1!", person: p, roles: ["csr"] )
end

When(/^CSR accesses the HBX portal$/) do
  visit '/'
  click_link 'HBX Portal'

  find('.interaction-click-control-sign-in-existing-account').click
  fill_in "user[login]", :with => "sherry.buckner@dc.gov"
  find('#user_email').set("sherry.buckner@dc.gov")
  fill_in "user[password]", :with => "aA1!aA1!aA1!"
  find('.interaction-click-control-sign-in').click
end

Then(/CSR should see the Agent Portal/) do
  expect(page).to have_content("a Trained Expert")
end

Then(/CSR opens the most recent Please Contact Message/) do
  expect(page).to have_content "Please contact"
  find(:xpath,'//*[@id="message_list_form"]/table/tbody/tr[2]/td[4]/a[1]').click
end

Then(/CSR clicks on Resume Application via phone/) do
  expect(page).to have_content "Assist Customer"
  click_link "Assist Customer"
end

When(/I click on the header link to return to CSR page/) do
  expect(page).to have_content "I'm a Trained Expert", :wait => 10
  find(:xpath, "//a[text()[contains(.,' a Trained Expert')]]").trigger('click')
end

Then(/CSR clicks on New Consumer Paper Application/) do
  click_link "New Consumer Paper Application"
end

Then(/CSR starts a new enrollment/) do
  expect(page).to have_content("Personal Information")
end

Then(/^click continue again$/) do
  wait_and_confirm_text /continue/i

  scroll_then_click(@browser.a(text: /continue/i))
end

Given(/^\w+ visits the Employee portal$/) do
  visit '/'
  click_link 'Employee Portal'
  screenshot("start")
  click_button 'Create account'
end

Then(/^(\w+) creates a new account$/) do |person|
  find('.interaction-click-control-create-account').click
  fill_in 'user[email]', with: (@u.email 'email' + person)
  fill_in 'user[password]', with: "aA1!aA1!aA1!"
  fill_in 'user[password_confirmation]', with: "aA1!aA1!aA1!"
  click_button 'Create account'
end

When(/^\w+ clicks continue$/) do
  find('.interaction-click-control-continue').click
end

When(/^\w+ selects Company match for (\w+)$/) do |company|
  expect(page).to have_content(company)
  find('#btn-continue').click
end

When(/^\w+ sees the (.*) page$/) do |title|
  expect(page).to have_content(title)
end

When(/^\w+ visits the Consumer portal$/i) do
  step "I visit the Insured portal"
end

When(/^(\w+) signs in$/) do |person|
  click_link 'Sign In Existing Account'
  fill_in 'user[login]', with: (@u.find 'email' + person)
  find('#user_email').set(@u.find 'email' + person)
  fill_in 'user[password]', with: "aA1!aA1!aA1!"
  click_button 'Sign in'
end

Given(/^Company Tronics is created with benefits$/) do
  step "I visit the Employer portal"
  step "Tronics creates an HBX account"
  step "Tronics should see a successful sign up message"
  step "I should click on employer portal"
  step "Tronics creates a new employer profile"
  step "Tronics creates and publishes a plan year"
  step "Tronics should see a published success message without employee"
end

Then(/^(\w+) enters person search data$/) do |insured|
  step "#{insured} sees the Personal Information page"
  person = people[insured]
  fill_in "person[first_name]", with: person[:first_name]
  fill_in "person[last_name]", with: person[:last_name]
  fill_in "jq_datepicker_ignore_person[dob]", with: person[:dob]
  fill_in "person[ssn]", with: person[:ssn]
  find(:xpath, '//label[@for="radio_female"]').click
  click_button 'CONTINUE'
end

Then(/^\w+ continues$/) do
  find('.interaction-click-control-continue').click
end

Then(/^\w+ continues again$/) do
  find('.interaction-click-control-continue').click
end

Then(/^\w+ enters demographic information$/) do
  step "Individual should see a form to enter personal information"
  fill_in 'person[emails_attributes][0][address]', with: "user#{rand(1000)}@example.com"
end

And(/^\w+ is an Employee$/) do
  wait_and_confirm_text /Employer/i
end

And(/^\w+ is a Consumer$/) do
  wait_and_confirm_text /Verify Identity/i
end

And(/(\w+) clicks on the purchase button on the confirmation page/) do |insured|
  person = people[insured]
  click_when_present(@browser.checkbox(class: /interaction-choice-control-value-terms-check-thank-you/))
  @browser.text_field(class: /interaction-field-control-first-name-thank-you/).set(person[:first_name])
  @browser.text_field(class: /interaction-field-control-last-name-thank-you/).set(person[:last_name])
  screenshot("purchase")
  click_when_present(@browser.a(text: /confirm/i))
end


Then(/^Aptc user create consumer role account$/) do
  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set("aptc@dclink.com")
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).set("aA1!aA1!aA1!")
  screenshot("aptc_create_account")
  scroll_then_click(@browser.input(value: "Create account"))
end

Then(/^Aptc user goes to register as individual/) do
  step "user should see your information page"
  step "user goes to register as an individual"
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Aptc")
  @browser.text_field(class: /interaction-field-control-person-ssn/).set(@u.ssn :ssn3)
  screenshot("aptc_register")

end

Then(/^Aptc user should see a form to enter personal information$/) do
  step "Individual should see a form to enter personal information"
  @browser.text_field(class: /interaction-field-control-person-emails-attributes-0-address/).set("aptc@dclink.com")
  screenshot("aptc_personal")
end

Then(/^Prepare taxhousehold info for aptc user$/) do
  person = User.find_by(email: 'aptc@dclink.com').person
  household = person.primary_family.latest_household

  start_on = TimeKeeper.date_of_record + 3.months

  if household.tax_households.blank?
    household.tax_households.create(is_eligibility_determined: TimeKeeper.date_of_record, allocated_aptc: 100, effective_starting_on: start_on, submitted_at: TimeKeeper.date_of_record)
    fm_id = person.primary_family.family_members.last.id
    household.tax_households.last.tax_household_members.create(applicant_id: fm_id, is_ia_eligible: true, is_medicaid_chip_eligible: true, is_subscriber: true)
    household.tax_households.last.eligibility_determinations.create(max_aptc: 80, determined_on: Time.now, csr_percent_as_integer: 40)
  end

  screenshot("aptc_householdinfo")
end

And(/Aptc user set elected amount and select plan/) do
  @browser.text_field(id: /elected_aptc/).wait_until_present
  @browser.text_field(id: "elected_aptc").set("20")

  click_when_present(@browser.a(text: /Select Plan/))
  screenshot("aptc_setamount")
end

Then(/Aptc user should see aptc amount and click on confirm button on thanyou page/) do
  click_when_present(@browser.checkbox(class: /interaction-choice-control-value-terms-check-thank-you/))
  expect(@browser.td(text: "$20.00").visible?).to be_truthy
  @browser.checkbox(id: "terms_check_thank_you").set(true)
  @browser.text_field(class: /interaction-field-control-first-name-thank-you/).set("Aptc")
  @browser.text_field(class: /interaction-field-control-last-name-thank-you/).set(@u.find :last_name1)
  screenshot("aptc_purchase")
  click_when_present(@browser.a(text: /confirm/i))
end

Then(/Aptc user should see aptc amount on receipt page/) do
  @browser.h1(text: /Enrollment Submitted/).wait_until_present
  expect(@browser.td(text: "$20.00").visible?).to be_truthy
  screenshot("aptc_receipt")

end

Then(/Aptc user should see aptc amount on individual home page/) do
  @browser.h1(text: /My #{Settings.site.short_name}/).wait_until_present
  expect(@browser.strong(text: "$20.00").visible?).to be_truthy
  expect(@browser.label(text: /APTC AMOUNT/).visible?).to be_truthy
  screenshot("aptc_ivl_home")

end
