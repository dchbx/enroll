Then(/^Hbx Admin should see an New DC Resident Application link$/) do
  find_link('New DC Resident Application').visible?
end

Then(/^Hbx Admin should not see an New DC Resident Application link$/) do
  expect(page).not_to have_content('New DC Resident Application')
end

When(/^Hbx Admin clicks on New DC Resident Application link$/) do
  find(:xpath, "//*[@id='inbox']/div/div[3]/div/span/div[1]/ul/li[3]/a").trigger('click')
end

Then(/^Hbx Admin should see New DC Resident Personal Information page$/) do
  expect(page).not_to have_content('Personal Information')
end

When(/HBX Admin goes to register an user as individual$/) do
  step "I use unique values"
  fill_in 'person[first_name]', :with => "Carlos"
  fill_in 'person[last_name]', :with => "Devina"
  fill_in 'jq_datepicker_ignore_person[dob]', :with => (@u.adult_dob :adult_dob)
  find(:xpath, '//label[@for="radio_male"]').trigger('click')
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
  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, '//*[@id="address_info"]/div/div[3]/div[2]/div/div[3]/div/ul/li[10]').click
  fill_in "person[addresses_attributes][0][zip]", :with => "20002"
  find('.btn', text: 'CONTINUE').click
end

Then(/^Hbx Admin should see text Household Info$/) do
  expect(page).to have_content('Household Info')
  expect(page).to have_content('get insurance coverage for other members of your household')
  find_link('Add Member').visible?
  find('.btn', text: 'CONTINUE').click
end

Then(/^Hbx Admin should see text Special Enrollment Period$/) do
  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "individual")
  expect(page).to have_content('Special Enrollment Period')
  expect(page).to have_content('TOP LIFE CHANGES')
  expect(page).to have_content('Married')
end

When(/Hbx Admin click the "(.*?)" in qle carousel/) do |qle_event|
  click_link "#{qle_event}"
end

When(/Hbx Admin select a past qle date/) do
  expect(page).to have_content "Married"
  screenshot("past_qle_date")
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
  find(:xpath, '//*[@id="plans"]/div[1]/div/div[5]/div[3]/a[1]').click
end

Then(/HBX Admin should see the summary page of plan selection/) do
  expect(page).to have_content('Confirm Your Plan Selection')
  screenshot("summary_page")
end

When(/HBX Admin clicks on Confirm button on the summary page of plan selection/) do
  find(:xpath, '//*[@id="terms_check_thank_you"]').click
  fill_in 'first_name_thank_you', :with => "Carlos"
  fill_in 'last_name_thank_you', :with => "Devina"
  find('.btn', text: 'CONFIRM').click
end

Then(/HBX Admin should see the enrollment receipt page/) do
  expect(page).to have_content('Enrollment Submitted')
  screenshot("receipt_page")
end

When(/HBX Admin clicks go to my account button/) do
  find('.btn', text: 'GO TO MY ACCOUNT').click
end

Then(/HBX Admin should see the home page with text coverage selected/) do
  expect(page).to have_content('Coverage Selected')
  screenshot("home_page")
end

Then(/^Hbx Admin should see an Transition family members link$/) do
  find_link('Transition Family Members').visible?
end

When(/^Hbx Admin clicks on Transition family members link$/) do
  FactoryGirl.create(:qualifying_life_event_kind, reason: 'eligibility_failed_or_documents_not_received_by_due_date', title: 'Not eligible for marketplace coverage due to citizenship or immigration status')
  click_link('Transition Family Members')
end

Then(/^Hbx Admin should see the form being rendered to transition each family memebers seperately$/) do
  expect(page).to have_content(/Transition Family Members/i)
  expect(page).to have_content(/Transition User?/i)
end

When(/^Hbx Admin enter\/update information of each memeber individually$/) do
  find(:xpath, "(//input[@type='checkbox'])[1]").trigger('click')
  find('input.date-picker').click
  find(:xpath, '/html/body/div[4]/table/tbody/tr[3]/td[4]/a').click
end

When(/^Hbx Admin clicks on submit button$/) do
  click_button 'Submit'
end

Then(/^Hbx Admin should show the Transition Results and the close button$/) do
  expect(page).to have_content(/Transition Results/i)
  expect(page).to have_content(/Close/i)
end

When(/^Hbx Admin clicks on close button$/) do
  click_link 'Close'
end

Then(/^Transition family members form should be closed$/) do
  expect(page).not_to have_content(/Transition Family Members/i)
end
