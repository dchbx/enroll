Given(/^the user answers no to having an income from an employer$/) do
  choose('has_job_income_false')
  sleep 1
end

Then(/^the job income form should not show$/) do
  expect(page).not_to have_xpath("//*[@id='financial_assistance_income_employer_name']")
  expect(page).not_to have_xpath("//*[@id='financial_assistance_income_employer_address_address_1']")
end

Given(/^the user answers no to having self employment income$/) do
  choose('has_self_employment_income_false')
  sleep 1
end

Then(/^self employment form should not show$/) do
  expect(page).not_to have_xpath("//*[@id='financial_assistance_income_amount']")
end

Given(/^the user answers yes to having and income from an employer$/) do
  choose('has_job_income_true')
  sleep 1
end

Then(/^the job income form should show$/) do
  expect(page).to have_xpath("//*[@id='financial_assistance_income_employer_name']")
  expect(page).to have_xpath("//*[@id='financial_assistance_income_employer_address_address_1']")
end


Given(/^the user answers yes to having self employment income$/) do
  choose('has_self_employment_income_true')
  sleep 1
end

Then(/^self employment form should show$/) do
  expect(page).to have_xpath("//*[@id='financial_assistance_income_amount']")
end

And(/^the user fills out the required employer information$/) do
  fill_in 'financial_assistance_income[employer_name]', with: "Sample Employer"
  fill_in 'financial_assistance_income[amount]', with: '23.3'
  find_all(".interaction-choice-control-financial-assistance-income-frequency-kind")[1].trigger('click')
  find_all('.interaction-choice-control-financial-assistance-income-frequency-kind-7')[1].trigger('click')
  fill_in 'financial_assistance_income[start_on]', with: "11/11/2016"
  fill_in 'financial_assistance_income[end_on]', with: "11/11/2017"
  page.find('.darkblue').click
  fill_in 'financial_assistance_income[employer_phone][full_phone_number]', with: "2036548484"
  fill_in 'financial_assistance_income[employer_address][address_1]', with: "12 main st"
  fill_in 'financial_assistance_income[employer_address][address_2]', with: "beside starbucks"
  fill_in 'financial_assistance_income[employer_address][city]', with: "washington"

  find_all(".interaction-choice-control-financial-assistance-income-employer-address-state")[2].trigger('click')
  find_all(".interaction-choice-control-financial-assistance-income-employer-address-state-5")[1].trigger('click')
  fill_in 'financial_assistance_income[employer_address][zip]', with: "22046"
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
  fill_in 'financial_assistance_income[employer_name]', with: "Sample Employer1"
  fill_in 'financial_assistance_income[amount]', with: '33.3'
  find_all(".interaction-choice-control-financial-assistance-income-frequency-kind")[1].trigger('click')
  find_all('.interaction-choice-control-financial-assistance-income-frequency-kind-7')[1].trigger('click')
  fill_in 'financial_assistance_income[start_on]', with: "11/11/2016"
  fill_in 'financial_assistance_income[end_on]', with: "11/11/2017"
  page.find('.darkblue').click
  fill_in 'financial_assistance_income[employer_phone][full_phone_number]', with: "2036548484"
  fill_in 'financial_assistance_income[employer_address][address_1]', with: "12 main st"
  fill_in 'financial_assistance_income[employer_address][address_2]', with: "beside starbucks1"
  fill_in 'financial_assistance_income[employer_address][city]', with: "washington"

  find_all(".interaction-choice-control-financial-assistance-income-employer-address-state")[2].trigger('click')
  find_all(".interaction-choice-control-financial-assistance-income-employer-address-state-5")[1].trigger('click')
  fill_in 'financial_assistance_income[employer_address][zip]', with: "22046"
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
  fill_in 'financial_assistance_income[amount]', with: '23.3'
  find(:xpath, "//*[@id='new_financial_assistance_income']/div[1]/div/div[2]/div").click
  find(:xpath, "//*[@id='new_financial_assistance_income']/div[1]/div/div[2]/div/div[3]/div/ul/li[3]").click
  fill_in 'financial_assistance_income[start_on]', with: "11/11/2016"
  fill_in 'financial_assistance_income[end_on]', with: "11/11/2017"
  page.find('.darkblue').click
end

Given(/^the user has entered at least one self employment information$/) do
  choose('has_self_employment_income_true')
  sleep 1
  fill_in 'financial_assistance_income[amount]', with: '23.3'
  find(:xpath, "//*[@id='new_financial_assistance_income']/div[1]/div/div[2]/div").click
  find(:xpath, "//*[@id='new_financial_assistance_income']/div[1]/div/div[2]/div/div[3]/div/ul/li[3]").click
  fill_in 'financial_assistance_income[start_on]', with: "11/11/2016"
  fill_in 'financial_assistance_income[end_on]', with: "11/11/2017"
  page.find('.darkblue').click
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