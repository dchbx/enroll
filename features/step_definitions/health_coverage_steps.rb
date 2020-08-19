Then(/^they should be taken to the applicant's Tax Info page \(health coverage\)$/) do
  expect(page).to have_content("Tax Info for #{consumer.person.first_name}")
end

Then(/^they visit the Health Coverage page via the left nav \(also confirm they are on the Health Coverage page\)$/) do
  visit financial_assistance_application_applicant_benefits_path(application.id, application.primary_applicant.id)
end

Given(/^the user answers no to currently having health coverage$/) do
  choose('has_enrolled_health_coverage_false')
end

Then(/^the health coverage choices should not show$/) do
  expect(page).not_to have_xpath("//*[@id='enrolled-benefit-kinds']")
end

Given(/^the user answers yes to currently having health coverage$/) do
  choose('has_enrolled_health_coverage_true')
end

Then(/^the health coverage choices should show$/) do
  expect(page).to have_xpath("//*[@id='enrolled-benefit-kinds']")
end

Given(/^the user answers no to currently having access to other health coverage$/) do
  choose('has_eligible_health_coverage_false')
end

Then(/^the other health coverage choices should not show$/) do
  expect(page).not_to have_xpath("//*[@id='eligible-benefit-kinds']")
end

Given(/^the user answers yes to currently having access to other health coverage$/) do
  choose('has_eligible_health_coverage_true')
end

Then(/^the other health coverage choices should show$/) do
  expect(page).to have_xpath("//*[@id='eligible-benefit-kinds']")
end

Given(/^the user checks a health coverage checkbox$/) do
  find(:css, "#insurance_kind[value='acf_refugee_medical_assistance']").set(true)
end

Then(/^the health coverage form should show$/) do
  expect(page).to have_xpath("//*[@id='acf_refugee_medical_assistance']/div[2]/div")
end

Then(/^the other health coverage form should show$/) do
  expect(page).to have_xpath("//*[@id='acf_refugee_medical_assistance']/div[2]")
end

Given(/^the user fills out the required health coverage information$/) do
  fill_in 'financial_assistance_benefit[start_on]', with: "02/01/2018"
end

Then(/^the user saves the health coverage information$/) do
  click_button 'Save'
end

Then(/^the health coverage should be saved on the page$/) do
 expect(page).to have_content '02/01/2018'
end

Then(/^the health coverage checkbox should be unchecked$/) do
  expect(find(:css, "#insurance_kind[value='acf_refugee_medical_assistance']")).not_to be_checked
end

Then(/^the health coverage form should not show$/) do
  expect(page).to_not have_content '02/01/2018'
end