# frozen_string_literal: true

Given(/^the user answers no to having an income from an employer$/) do
  choose('has_job_income_false')
  sleep 1
end

Then(/^the job income form should not show$/) do
  expect(page).not_to have_xpath("//*[@id='income_employer_name']")
  expect(page).not_to have_xpath("//*[@id='income_employer_address_address_1']")
end

Given(/^the user answers no to having self employment income$/) do
  choose('has_self_employment_income_false')
  sleep 1
end

Then(/^self employment form should not show$/) do
  expect(page).not_to have_xpath("//*[@id='income_amount']")
end

Given(/^the user answers yes to having and income from an employer$/) do
  choose('has_job_income_true')
  sleep 1
end

Then(/^the job income form should show$/) do
  expect(page).to have_xpath("//*[@id='income_employer_name']")
  expect(page).to have_xpath("//*[@id='income_employer_address_address_1']")
end

Given(/^the user answers yes to having self employment income$/) do
  choose('has_self_employment_income_true')
  sleep 1
end

Then(/^self employment form should show$/) do
  expect(page).to have_xpath("//*[@id='income_amount']")
end

And(/^the user fills out the required employer information$/) do
  fill_in 'income[employer_name]', with: "Sample Employer"
  fill_in 'income[amount]', with: '23.3'
  find_all(".interaction-choice-control-income-frequency-kind")[1].click
  find_all('.interaction-choice-control-income-frequency-kind-7')[0].click
  fill_in 'income[start_on]', with: "11/11/2016"
  fill_in 'income[end_on]', with: "11/11/2017"
  fill_in 'income[employer_phone][full_phone_number]', with: "2036548484"
  fill_in 'income[employer_address][address_1]', with: "12 main st"
  fill_in 'income[employer_address][address_2]', with: "beside starbucks"
  fill_in 'income[employer_address][city]', with: "washington"
  find_all(".interaction-choice-control-income-employer-address-state")[0].click
  find_all(".interaction-choice-control-income-employer-address-state-5")[0].click
  fill_in 'income[employer_address][zip]', with: "22046"
end

And(/^the user fills out the required employer information with incorrect dates$/) do
  fill_in 'income[employer_name]', with: "Sample Employer"
  fill_in 'income[amount]', with: '23.3'
  find_all(".interaction-choice-control-income-frequency-kind")[1].click
  find_all('.interaction-choice-control-income-frequency-kind-7')[0].click
  fill_in 'income[start_on]', with: "11/11/2017"
  fill_in 'income[end_on]', with: "11/11/2016"
  fill_in 'income[employer_phone][full_phone_number]', with: "2036548484"
  fill_in 'income[employer_address][address_1]', with: "12 main st"
  fill_in 'income[employer_address][address_2]', with: "beside starbucks"
  fill_in 'income[employer_address][city]', with: "washington"
  find_all(".interaction-choice-control-income-employer-address-state")[0].click
  find_all(".interaction-choice-control-income-employer-address-state-5")[0].click
  fill_in 'income[employer_address][zip]', with: "22046"
end

And(/^the user saves the employer information$/) do
  find('.interaction-click-control-save').click
end

Then(/^the employer information should be saved on the page$/) do
  expect(page).to have_content("Sample Employer")
  expect(page).to have_content("23.3")
  expect(page).to have_content("beside starbucks")
end

Given(/^the user has entered at least one job income information$/) do
  choose('has_job_income_true')
  sleep 1
  fill_in 'income[employer_name]', with: "Sample Employer1"
  fill_in 'income[amount]', with: '33.3'
  find_all(".interaction-choice-control-income-frequency-kind")[1].click
  find_all('.interaction-choice-control-income-frequency-kind-7')[0].click
  fill_in 'income[start_on]', with: "11/11/2016"
  fill_in 'income[end_on]', with: "11/11/2017"
  fill_in 'income[employer_phone][full_phone_number]', with: "2036548484"
  fill_in 'income[employer_address][address_1]', with: "12 main st"
  fill_in 'income[employer_address][address_2]', with: "beside starbucks1"
  fill_in 'income[employer_address][city]', with: "washington"
  find_all(".interaction-choice-control-income-employer-address-state")[0].click
  find_all(".interaction-choice-control-income-employer-address-state-5")[0].click
  fill_in 'income[employer_address][zip]', with: "22046"
  find('.interaction-click-control-save').click
end

When(/^the Add Another Job Income link appears$/) do
  find('.interaction-click-control-add-another-job-income').visible?
end

When(/^the user adds another income$/) do
  find('.interaction-click-control-add-another-job-income').click
end

Then(/^the new employer information should be saved on the page$/) do
  expect(page).to have_content("Sample Employer")
  expect(page).to have_content("23.3")
  expect(page).to have_content("beside starbucks")
  expect(page).to have_content("Sample Employer1")
  expect(page).to have_content("33.3")
  expect(page).to have_content("beside starbucks1")
end

And(/^the user fills out the required self employment information$/) do
  fill_in 'income[amount]', with: '23.3'
  find_all("#self_employed_incomes .incomes-list .interaction-choice-control-income-frequency-kind span.label").first.click
  find_all("#self_employed_incomes li.interaction-choice-control-income-frequency-kind-7").first.click
  fill_in 'income[start_on]', with: "11/11/2016"
  fill_in 'income[end_on]', with: "11/11/2017"
end

And(/^the user fills out the required self employment information with incorrect dates$/) do
  fill_in 'income[amount]', with: '23.3'
  find_all("#self_employed_incomes .incomes-list .interaction-choice-control-income-frequency-kind span.label").first.click
  find_all("#self_employed_incomes li.interaction-choice-control-income-frequency-kind-7").first.click
  fill_in 'income[start_on]', with: "11/11/2017"
  fill_in 'income[end_on]', with: "11/11/2016"
end

Given(/^the user has entered at least one self employment information$/) do
  choose('has_self_employment_income_true')
  sleep 1
  fill_in 'income[amount]', with: '23.3'
  find_all("#self_employed_incomes .incomes-list .interaction-choice-control-income-frequency-kind span.label").first.click
  find_all("#self_employed_incomes li.interaction-choice-control-income-frequency-kind-7").first.click
  fill_in 'income[start_on]', with: "11/11/2016"
  fill_in 'income[end_on]', with: "11/11/2017"
  find('.interaction-click-control-save').click
end

Then(/^the self employment information should be saved on the page$/) do
  expect(page).to have_content("23.3")
end

When(/^the Add Another Self Employment link appears$/) do
  find('.interaction-click-control-add-another--self-employed-income').visible?
end

And(/^the user adds another self employment income$/) do
  find('.interaction-click-control-add-another--self-employed-income').click
end

When(/^the user saves the self employment information$/) do
  find('.interaction-click-control-save').click
end

Given(/^the user is on the Job Income page$/) do
  expect(page).to have_content("Job Income for")
end

When(/^the user clicks the Not sure link next to the (.*) income question$/) do |income_type|
  sleep 2
  links = page.all('a')
  case income_type
  when 'employer'
    popup_link = links.detect { |link| link[:href].include?("#has_job_income") unless link[:href].blank? }
  when 'self employment'
    popup_link = links.detect { |link| link[:href].include?("#has_self_employment_income") unless link[:href].blank? }
  end
  popup_link.click
  sleep 2
end

And(/^the user closes the open income question modal$/) do
  close_button = page.all('button').detect { |button| button[:class] == 'close interaction-click-control-×' }
  close_button.click
end

Then(/^the user should see the popup for the (.*) income question$/) do |income_type|
  case income_type
  when 'job'
    # stuff
    popup_text = "Select ‘yes’ if this person is considered an employee of a business, or receives a W-2 federal form from any employer. " \
    "We need to know about all income this person receives from an employer, including wages, tips, salaries, and bonuses."
  when 'self employment'
    popup_text = "Select 'yes' if this person owns a business or receives a federal form 1099 from any employer. " \
    "We need to know about any income this person receives as an independent contractor or from a business they own."
  end
  expect(page).to have_content(popup_text)
end

Then(/^the user will be on the Other Income page$/) do
  expect(page).to have_content("Other Income for")
end

And(/^there will be a checkmark next to the completed Job Income page link$/) do
  checkmark = page.all('span').detect { |span| span[:class] == "fa fa-check applicant-check" }
  expect(checkmark.present?).to eq(true)
end

