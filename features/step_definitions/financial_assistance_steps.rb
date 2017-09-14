Given(/^a consumer, with a family, exists$/) do
  consumer :with_nuclear_family
end

Given(/^is logged in$/) do
  login_as consumer, scope: :user
end

Given(/^a benchmark plan exists$/) do
  FactoryGirl.create :plan, active_year: 2017, hios_id: "86052DC0400001-01"
end

When /^the consumer views their applications$/ do
  visit financial_assistance_applications_path
end

When(/^they click 'New Financial Assistance Application' button$/) do
  click_button "Start new application"
end

Then(/^they should see a new finanical assistance application$/) do
  expect(page.current_url).to match("/applications/#{consumer.primary_family.application_in_progress.id}/edit")
end

Then(/^they should see each of their dependents listed$/) do
  consumer.person.primary_family.family_members.each do |family_member|
    expect(page).to have_content(family_member.full_name)
  end
end

Given(/^the consumer has started a financial assistance application$/) do
  application
end

When(/^they view the financial assistance application$/) do
  visit edit_financial_assistance_application_path(application)
end

Then(/^they should be taken back to the application's details page for applicant$/) do
  page.should have_content('Applicant deleted.')
end

When(/^they click edit for an applicant$/) do
  click_link 'ADD INCOME & COVERAGE INFO', href: "/financial_assistance/applications/#{consumer.primary_family.application_in_progress.id}/applicants/#{consumer.primary_family.application_in_progress.primary_applicant.id}/step/1"
end

When(/^they complete and submit the Income and Coverage information$/) do
  choose("income_from_employer_yes")
  choose("self_employed_no")
  choose("other_income_no")
  choose("adjustments_income_no")
  choose("enrolled_in_coverage_no")
  choose("access_to_other_coverage_no")

  click_button 'CONTINUE'
end

Then(/^they should be taken to the applicant's Tax Info page$/) do
  expect(page).to have_content("Tax Info for #{consumer.person.first_name}")
end

Given(/^has added tax information for an applicant$/) do
  # right now this step is unnecessary but not always be
end

Given(/^they visit the applicant's Income page$/) do
  visit financial_assistance_application_applicant_incomes_path(application, application.primary_applicant)
end

Given(/^they visit the applicant's Benefits page$/) do
  visit financial_assistance_application_applicant_benefits_path(application, application.primary_applicant)
end

Given(/^they visit the applicant's Deductions page$/) do
  visit financial_assistance_application_applicant_deductions_path(application, application.primary_applicant)
end

And(/^they click on the 'Add Income' button$/) do
  click_link 'Add Income'
end

And(/^they complete the form for the income$/) do
  fill_in 'income[amount]', with: '23.3'
  find_all(".interaction-choice-control-employer-address-state")[1].click
  find_all(".interaction-choice-control-income-frequency-kind-1")[1].click
  fill_in 'income[start_on]', with: "11/11/2016"
  fill_in 'income[end_on]', with: "11/11/2017"
  fill_in 'income[employer_name]', with: "Sample Employer 1"
  fill_in 'employer_phone[full_phone_number]', with: "2036548484"
  fill_in 'employer_address[address_1]', with: "12 main st"
  fill_in 'employer_address[address_2]', with: "beside starbucks"
  fill_in 'employer_address[city]', with: "washington"
  find('#employer_address_state').select('DC')
  fill_in 'employer_address[zip]', with: "22046"

  click_button 'CONTINUE'
end

And(/^they click on 'Remove Income' button$/) do
  find(:xpath, '//a[@data-method="delete"][span]').click
  page.accept_alert
end

And(/^they should see the newly added income/) do
  page.should have_content('Income Added')
end


Then(/^they should be taken back to the application's details page for income$/) do
  page.should have_content("Income for #{consumer.person.first_name}")
end

Then(/^the income should be no longer be shown$/) do
  page.should have_content('Income deleted')
end

Then(/^the benefit should be no longer be shown$/) do
  page.should have_content('Benefit deleted')
end

Then(/^the deduction should be no longer be shown$/) do
  page.should have_content('Deduction deleted')
end

Given(/^the consumer has completed a financial assistance application$/) do
  # Kelly to John
  application.applicants.second.person.person_relationships.create kind: 'spouse',
    family_id: consumer.primary_family.id,
    successor_id: application.applicants.first.person.id,
    predecessor_id: application.applicants.second.person.id

  # Danny to John
  application.applicants.third.person.person_relationships.create kind: 'parent',
    family_id: consumer.primary_family.id,
    successor_id: application.applicants.first.person.id,
    predecessor_id: application.applicants.third.person.id

  # Danny to Kelly
  application.applicants.third.person.person_relationships.create kind: 'parent',
    family_id: consumer.primary_family.id,
    successor_id: application.applicants.second.person.id,
    predecessor_id: application.applicants.third.person.id

  application.applicants.each do |applicant|
    applicant.update_attributes is_required_to_file_taxes: false,
      is_claimed_as_tax_dependent: false,
      is_living_in_state: false,
      is_temp_out_of_state: false,
      has_other_income: false,
      has_deductions: false,
      has_enrolled_health_coverage: false
  end
end

When(/^they view the financial assistance application for review$/) do
  visit edit_financial_assistance_application_path(application)
end

And (/^click the 'Review and Continue' button$/) do
  click_link "Continue"
end

And (/^they review and submit the application$/) do
  click_link 'Continue'
end

When(/^click the "([^"]*)" button$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^they are taken back to view all applications$/) do
  visit financial_assistance_applications_path
end

Then(/^they will see that their application has been submitted$/) do
  page.find(".interaction-click-control-start-new-application")
end

When(/^they click on the 'Add Income Adjustment' button$/) do
  click_link 'Add Income Adjustment'
end

When (/^they click on 'Add Benefit' button$/) do
  click_link 'Add Health Coverage'
end

# And (/^has added an benefit$/) do
#   choose("yes2")
#   find('#benefit_kind').select('medicare')
#   fill_in 'benefit[start_on]', with: "11/11/2016"
#   fill_in 'benefit[end_on]', with: "11/11/2017"
#   click_button 'Next step'
#   choose("access_to_hc_yes")
#   fill_in 'benefit[employer_name]', with: "JOHN"
#   fill_in 'employer_address[address_1]', with: " Test address 1"
#   fill_in 'employer_address[city]', with: " Herdon"
#   fill_in 'employer_address[zip]', with: " 51023"
#   choose("is_eligible_no")
#   choose("health_plan_yes")
#   fill_in 'benefit[employee_cost]', with: " 2.3"
# end

And (/^they complete the form for the benefit$/) do
  find('#is_eligible').click
  find('#benefit_insurance_kind').select('Acf Refugee Medical Assistance')
  click_button 'CONTINUE'
end

Then(/^they should be taken back to the applicant's detail page$/) do

end
And (/^they should see the newly added benefit$/) do
  page.should have_content('Benefit Info Added.')
end

# When (/^they view the applicant's details page$/) do
#   page.should have_content('Edit Applicant')
# end

When (/^they click on 'Remove Benefit' button/) do
  find(:xpath, '//a[@data-method="delete"][span]').click
  page.accept_alert
end

When(/^they click on 'Remove Deduction' button$/) do
  find(:xpath, '//a[@data-method="delete"][span]').click
  page.accept_alert
end

And (/^they should be taken back to the application's details page for benefit$/) do
  page.should have_content("Health Coverage for #{consumer.person.first_name}")
end

## Remove Deduction

When (/^they click on 'Add Deduction' button$/) do
  click_link 'Add Deductions'
end

And (/^they complete the form for the deduction/) do
  find('#deduction_kind').select('Alimony Paid')
  find('#deduction_frequency_kind').select('quarterly')
  fill_in 'deduction[amount]', with: "2.2"
  # find_all(".interaction-choice-control-deduction-frequency-kind")[2].click
  fill_in 'deduction[start_on]', with: "10/11/2016"
  fill_in 'deduction[end_on]', with: "11/18/2016"
  click_button 'CONTINUE'
end

Given (/^the consumer has an income$/) do
  consumer.primary_family.application_in_progress.applicants.first.incomes.create amount: '5000',
    frequency_kind: 'monthly',
    employer_name: 'Ideacrew',
    start_on: '2017/01/01',
    end_on: '2017/12/31',
    employer_address: {
      kind: 'primary',
      address_1: '2nd St',
      city: 'Washington',
      state: 'DC',
      zip: '20001' },
    employer_phone: {
        kind: 'phone main',
        full_phone_number: '202-222-2222' }
end

Given (/^the consumer has a benefit$/) do
  consumer.primary_family.application_in_progress.applicants.first.update_attributes has_enrolled_health_coverage: true
end

Given (/^the consumer has a deduction$/) do
  consumer.primary_family.application_in_progress.applicants.first.deductions.create! kind: 'alimony_paid'
end

And (/^they should see the newly added deduction$/) do
  page.should have_content('Deduction Added')
end

Then (/^they click on 'Remove deduction' button/) do
  page.find('.interaction-click-control-delete').click
  page.accept_alert
end

And (/^they should be taken back to the application's details page for deduction$/) do
  page.should have_content("Income Adjustments for #{consumer.person.first_name}")
end
