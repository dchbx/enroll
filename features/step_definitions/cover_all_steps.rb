Then(/^Hbx Admin should see an DC Resident Application link$/) do
  find_link("#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item} Resident Application").visible?
end

Then(/^Hbx Admin should not see an New DC Resident Application link$/) do
  expect(page).not_to have_content('New DC Resident Application')
end

Then(/^Hbx Admin should see a DC Resident Application link disabled$/) do
  find_link("#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item} Resident Application")[:class].include?("blocking") == false
end

When(/^Hbx Admin clicks on New DC Resident Application link$/) do
  find(:xpath, "//*[@id='inbox']/div/div[3]/div/span/div[1]/ul/li[3]/a").click
end

Then(/^Hbx Admin should not see an New Consumer Phone Application link and New Consumer Paper Application link$/) do
  expect(page).not_to have_content('New Consumer Phone Application')
  expect(page).not_to have_content('New Consumer Paper Application')
end

When(/^Hbx Admin clicks on DC Resident Application link$/) do
  find_link("#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item} Resident Application").click
end

Then(/^Hbx Admin should see DC Resident Personal Information page$/) do
  expect(page).to have_content('Personal Information')
end

When(/HBX Admin goes to register an user as individual$/) do
  step "I use unique values"
  fill_in 'person[first_name]', :with => "Carlos"
  fill_in 'person[last_name]', :with => "Devina"
  fill_in 'jq_datepicker_ignore_person[dob]', :with => (@u.adult_dob :adult_dob)
  find(:xpath, '//label[@for="radio_male"]').click
  find('.btn', text: 'CONTINUE').click
end

Then(/^HBX Admin clicks on continue button$/) do
  click_link "Continue"
end

Then(/HBX Admin should see a form to enter personal information$/) do
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click

  fill_in "person_addresses_attributes_0_address_1", :with => "4900 USAA BLVD"
  fill_in "person_addresses_attributes_0_address_2", :with => "212"
  fill_in "person_addresses_attributes_0_city", :with=> "Washington"
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'DC')]").click
  fill_in "person[addresses_attributes][0][zip]", :with => "20002"
  # expect(page).to have_css("#home_address_tooltip")
  find('.btn', text: 'CONTINUE').click
end

Then(/^Hbx Admin should see text Household Info$/) do
  expect(page).to have_content("#{l10n('family_information')}")
  expect(page).to have_content('get health insurance coverage for other members of your family')
  find_link('Add Member').visible?
  find('.btn', text: 'CONTINUE').click
end

Then(/^Hbx Admin should see text Special Enrollment Period$/) do
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  sleep 2
  expect(page).to have_content('Special Enrollment Period')
  expect(page).to have_content('TOP LIFE CHANGES')
  expect(page).to have_content('Married')
end

When(/Hbx Admin click the "(.*?)" in qle carousel/) do |qle_event|
  click_link "#{qle_event}"
end

When(/Hbx Admin select a past qle date/) do
  expect(page).to have_content "Married"
  # screenshot("past_qle_date")
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  find('h1').click
  within '#qle-date-chose' do
    click_link "CONTINUE"
  end
end

Then(/Hbx Admin should see confirmation and clicks continue/) do
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  click_button "Continue"
end

When(/HBX Admin selects a plan from shopping plan page/) do
  find(:xpath, '//*[@id="ivl_plans"]/div[1]/div/div[5]/div[3]/a[1]').click
end

Then(/HBX Admin should see the summary page of plan selection/) do
  expect(page).to have_content('Confirm Your Plan Selection')
  # screenshot("summary_page")
end

When(/HBX Admin clicks on Confirm button on the summary page of plan selection/) do
  find(:xpath, '//*[@id="terms_check_thank_you"]').click
  fill_in 'first_name_thank_you', :with => "Carlos"
  fill_in 'last_name_thank_you', :with => "Devina"
  find('.btn', text: 'CONFIRM').click
end

Then(/HBX Admin should see the enrollment receipt page/) do
  expect(page).to have_content('Enrollment Submitted')
  # screenshot("receipt_page")
end

When(/HBX Admin clicks go to my account button/) do
  find('.btn', text: 'GO TO MY ACCOUNT').click
end

When(/(.*) is clicked by HBX Admin/) do |btn|
  find('.btn', text: btn).click
end

Then(/HBX Admin should see the home page with text coverage selected/) do
  expect(page).to have_content('Coverage Selected')
  # screenshot("home_page")
end

Then(/^HBX Admin should see broker assister search box$/) do
  expect(page).to have_content('Select a Broker or Assister')
end

Then(/^Hbx Admin should see an Transition family members link$/) do
  find_link('Transition Family Members').visible?
end

When(/^Hbx Admin clicks Transition family members link$/) do
  FactoryBot.create(:qualifying_life_event_kind, reason: 'eligibility_failed_or_documents_not_received_by_due_date', title: 'Not eligible for marketplace coverage due to citizenship or immigration status')
  click_link('Transition Family Members')
end

Then(/^Hbx Admin should see the form being rendered to transition each family members seperately$/) do
  expect(page).to have_content(/Transition Family Members/i)
  expect(page).to have_content(/Transition User?/i)
end

When(/^Hbx Admin enter\/update information of each member individually$/) do
  find("#transition_user", wait: 5).click
  find('input.date-picker').click
  find('.ui-state-highlight', wait: 5).click
end

When(/^Hbx Admin clicks submit button$/) do
  click_button 'Submit'
end

Then(/^Hbx Admin should show the Transition Results and the close button$/) do
  page.driver.browser.switch_to.alert.accept
  expect(page).to have_content(/Market Transitions Added/i)
  expect(page).to have_content(/Close/i)
end

When(/^Hbx Admin clicks close button$/) do
  click_link 'Close'
end

Then(/^Transition family members form should be closed$/) do
  expect(page).not_to have_content(/Transition Family Members/i)
end
