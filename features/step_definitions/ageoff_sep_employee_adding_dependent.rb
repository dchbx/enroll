# frozen_string_literal: true

When(/^.+ sees the new dependent form$/) do
  expect(page).to have_content('CONFIRM MEMBER')
end

When(/^.+ enters? the info of his dependent wife$/) do
  fill_in 'dependent[first_name]', with: 'Cynthia'
  fill_in 'dependent[last_name]', with: 'Patrick'
  fill_in 'dependent[ssn]', with: '123445678'
  fill_in 'jq_datepicker_ignore_dependent[dob]', with: '09/15/1994'
  find(:xpath, "//label[@for='radio_female']").click
  sleep 1
  find(:xpath, "//span[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, "//li[@data-index='1'][contains(., 'Spouse')]").click
  fill_in 'dependent[addresses][0][address_1]', with: '123 STREET'
  fill_in 'dependent[addresses][0][city]', with: 'WASHINGTON'
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[@data-index='24'][contains(., 'MA')]").click
  fill_in 'dependent[addresses][0][zip]', with: '01001'
end

When(/(.*) clicks "(.*?)" link in the qle carousel$/) do |_name, qle_event|
  click_link qle_event.to_s
end

When(/employee selects a current qle date$/) do
  expect(page).to have_content "Married"
  screenshot("past_qle_date")
  fill_in "qle_date", :with => TimeKeeper.date_of_record.strftime("%m/%d/%Y")
  within '#qle-date-chose' do
    find('.interaction-click-control-continue').click
  end
end

Then(/Employee should see confirmation and click on continue$/) do
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  screenshot("valid_qle")
  click_button "Continue"
end

Then(/(.*) sees the QLE confirmation message and clicks on continue$/) do |_person|
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  screenshot("valid_qle")
  click_button "Continue"
end

And(/^.+ sees the list of plans$/) do
  find('#planContainer', wait: 10)
  expect(page).to have_link('Select')
  screenshot("plan_shopping")
end

Then(/(.*) should see his active enrollment including his wife$/) do |_person|
  sleep 1
  expect(page).to have_content "Cynthia"
end
