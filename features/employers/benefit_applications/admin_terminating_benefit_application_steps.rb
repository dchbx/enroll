# frozen_string_literal: true

Then(/^the user will select benefit application to terminate$/) do
  find(:xpath, '//input[@name="plan_year_radio"]').click
end

When(/^the user clicks Actions for that benefit application$/) do
  find('.py-btn-grp', text: 'Actions').click
end

Then(/^the user will see Terminate button$/) do
  find('li', :text => 'Terminate').click
end

When(/^the user enters (mid_month|any_day|last_day) and other details for (voluntary|non-payment) termination$/) do |termination_date, termination_type|
  if termination_type == 'voluntary'
    find(:xpath, '//input[@id="term_actions_voluntary"]').click
  else
    find(:xpath, '//input[@id="term_actions_nonpayment"]').click
  end

  if termination_date == 'mid_month'
    fill_in "Select Term Date", with: TimeKeeper.date_of_record.end_of_month.prev_day.strftime('%m/%d/%Y').to_s
  elsif termination_date == 'any_day'
    fill_in "Select Term Date", with: TimeKeeper.date_of_record.end_of_month.strftime('%m/%d/%Y').to_s
  elsif termination_date == 'last_day'
    fill_in "Select Term Date", with: @new_application.end_on.to_s
  end
  find('h1', :text => 'Employers', wait: 10).click
end

When(/^user clicks submit button$/) do
  find('.plan-year-submit', text: 'SUBMIT', wait: 5).click
end

Then(/^user should see termination successful message$/) do
  expect(page).to have_content('Application terminated successfully')
end