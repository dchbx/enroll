# frozen_string_literal: true

Given(/^all applicants fill all pages except other questions$/) do
  until find_all('.btn', text: 'ADD INCOME & COVERAGE INFO').empty?
    find_all('.btn', text: 'ADD INCOME & COVERAGE INFO')[0].click
    find('#is_required_to_file_taxes_no').click
    find('#is_claimed_as_tax_dependent_no').click
    find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click

    find('#has_job_income_true').click
    sleep 1
    fill_in 'income[employer_name]', with: 'GloboGym'
    fill_in 'income[amount]', with: '100'
    fill_in 'income[start_on]', with: '1/1/2018'
    find(:xpath, '//*[@id="new_income"]/div[1]/div[2]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_income"]/div[1]/div[2]/div[2]/div/div[3]/div/ul/li[2]').click
    fill_in 'income[employer_address][address_1]', with: '1 K Street'
    fill_in 'income[employer_address][city]', with: 'Washington'
    fill_in 'income[employer_address][zip]', with: '20000'
    find(:xpath, '//*[@id="new_income"]/div[1]/div[4]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_income"]/div[1]/div[4]/div[2]/div/div[3]/div/ul/li[10]').click
    fill_in 'income[employer_phone][full_phone_number]', with: '7898765676'
    click_button('Save')
    find('#has_self_employment_income_true').click
    fill_in 'income[amount]', with: '100.00'
    find(:xpath, '//*[@id="new_income"]/div[1]/div/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_income"]/div[1]/div/div[2]/div/div[3]/div/ul/li[3]').click
    fill_in 'income[start_on]', with: '01/01/2018'
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find('#has_other_income_true').click
    sleep 1
    find(:css, "#other_income_kind[value='interest']").set(true)
    fill_in 'income[amount]', with: '100'
    fill_in 'income[start_on]', with: '1/1/2018'
    find(:xpath, '//*[@id="new_income"]/div/div[1]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_income"]/div/div[1]/div[2]/div/div[3]/div/ul/li[3]').click
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find('#has_deductions_true').click
    find(:css, "#deduction_kind[value='moving_expenses']").set(true)
    fill_in 'deduction[amount]', with: '50'
    fill_in 'deduction[start_on]', with: '1/1/2018'
    find(:xpath, '//*[@id="new_deduction"]/div/div[1]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_deduction"]/div/div[1]/div[2]/div/div[3]/div/ul/li[5]').click
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find('#has_enrolled_health_coverage_false').click
    find('#has_eligible_health_coverage_false').click

    find(:xpath, '//*[@id="btn-continue"]').click
  end
end

Given(/^the user will navigate to the FAA Household Info page$/) do
  visit financial_assistance.edit_application_path(application.id.to_s)
end

Given(/^the user SSN is nil$/) do
  consumer.person.update_attributes(no_ssn: "1")
end

Given(/^the user has an eligible immigration status$/) do
  consumer.person.consumer_role.update_attributes(citizen_status: "alien_lawfully_present")
end

Given(/^the user has an age between (\d+) and (\d+) years old$/) do |_arg1, _arg2|
  consumer.person.update_attributes(dob: TimeKeeper.date_of_record - 19.years)
end

Then(/^the have you applied for an SSN question should display$/) do
  expect(page).to have_content('Has this person applied for an SSN *')
end

And(/^the user answers no to the have you applied for an SSN question$/) do
  choose('is_ssn_applied_no')
end

Then(/^the reason why question is displayed$/) do
  expect(page).to have_content('Why doesn\'t this person have an SSN?')
end

Given(/^the user answers yes to being pregnant$/) do
  choose('is_pregnant_yes')
end

Then(/^the due date question should display$/) do
  expect(page).to have_content('Pregnancy due date')
end

And(/^the user enters a pregnancy due date of one month from today$/) do
  fill_in "applicant_pregnancy_due_on", with: (TimeKeeper.date_of_record + 1.month).to_s
  # Click off datepicker to close
  find('.fa-darkblue', match: :first).click
end

And(/^the user enters a pregnancy end date of one month ago$/) do
  fill_in "applicant_pregnancy_end_on", with: (TimeKeeper.date_of_record - 1.month).to_s
end

And(/^the user answers two for how many children$/) do
  find(".selectric-interaction-choice-control-children-expected-count").click
  sleep 1
  find('.interaction-choice-control-children-expected-count-2', match: :first).click
end

And(/^the user fills out the rest of the other questions form and submits it$/) do
  choose('is_ssn_applied_no')
  find("#has_daily_living_no").click
  find("#need_help_paying_bills_no").click
  find("#radio_physically_disabled_no").click
  choose('is_former_foster_care_no')
  choose('is_student_no')
  choose('is_self_attested_blind_no')
  choose('is_veteran_or_active_military_no')
  choose("is_resident_post_092296_no")
  choose("medicaid_pregnancy_no") if page.all("#medicaid_pregnancy_no").present?
  find('[name=commit]').click
end

And(/^the user fills out the rest of form with medicaid during pregnancy as yes and submits it$/) do
  choose('is_ssn_applied_no')
  find("#has_daily_living_no").click
  find("#need_help_paying_bills_no").click
  find("#radio_physically_disabled_no").click
  choose('is_former_foster_care_no')
  choose('is_student_no')
  choose('is_self_attested_blind_no')
  choose('is_veteran_or_active_military_no')
  choose("is_resident_post_092296_no")
  choose("medicaid_pregnancy_yes") if page.all("#medicaid_pregnancy_yes").present?
  find('[name=commit]').click
end

And(/^the info complete applicant has an attribute is_enrolled_on_medicaid that is set to true$/) do
  last_application = FinancialAssistance::Application.last
  complete_applicant = last_application.applicants.detect { |applicant| applicant.applicant_validation_complete? }
  expect(complete_applicant.is_enrolled_on_medicaid).to eq(true)
end

Then(/^the user should see text that the info is complete$/) do
  expect(page).to have_content("Info Complete")
end


And(/^how many children question should display$/) do
  expect(page).to have_content('How many children is this person expecting?')
end

Given(/^the user answers no to being pregnant$/) do
  choose('is_pregnant_no')
end

And(/^was this person pregnant in the last (\d+) days question should display$/) do |_arg1|
  expect(page).to have_content('Was this person pregnant in the last 60 days?')
end

When(/^they answer yes to was this person pregnant in the last (\d+) days question$/) do |_arg1|
  choose('is_post_partum_period_yes')
end

Then(/^pregnancy end date question should display$/) do
  expect(page).to have_content('Pregnancy end on date')
end

Then(/^the is this person a student question should display$/) do
  expect(page).to have_content('Is this person a student? *')
end

Given(/^the user answers yes to being a student$/) do
  choose('is_student_yes')
end

And(/^the type of student question should display$/) do
  expect(page).to have_content('What is the type of student?')
end

And(/^student status end date question should display$/) do
  expect(page).to have_content('Student status end on date?')
end

Then(/^type of school question should display$/) do
  expect(page).to have_content('What type of school do you go to?')
end

Then(/^the has this person ever been in foster care question should display$/) do
  expect(page).to have_content('Was this person in foster care at age 18 or older? *')
end

Given(/^the user answered yes to the has this person ever been in foster care question$/) do
  choose('is_former_foster_care_yes')
end

Then(/^the where was this person in foster care question should display$/) do
  expect(page).to have_content('Where was this person in foster care?')
end

Then(/^the how old was this person when they left foster care question should display$/) do
  expect(page).to have_content('How old was this person when they left foster care?')
end

Then(/^the was this person enrolled in medicare when they left foster care should display$/) do
  expect(page).to have_content('Was this person enrolled in Medicaid when they left foster care?')
end

And(/^the user answers yes to having an eligible immigration status$/) do
  str1_markerstring = "applications/"
  str2_markerstring = "/applicants"

  application_id = page.current_path[/#{str1_markerstring}(.*?)#{str2_markerstring}/m, 1]
  str1_markerstring = "applicants/"
  str2_markerstring = "/other_questions"

  applicant_id = page.current_path[/#{str1_markerstring}(.*?)#{str2_markerstring}/m, 1]
  application = FinancialAssistance::Application.where(id: application_id).first
  current_applicant = application.applicants.find(applicant_id)
  expect(current_applicant.eligible_immigration_status).to eq(true)
end

Then(/^the did you move to the US question should display$/) do
  expect(page).to have_content('Did you move to the U.S. on or after August 22, 1996?')
end

Then(/^the military veteran question should display$/) do
  expect(page).to have_content('Are you an honorably discharged veteran or active duty member of the military?')
end

Given(/^user answers no to the military veteran question$/) do
  choose('is_veteran_or_active_military_no')
end

Then(/^the are you a spouse of such a veteran question should display$/) do
  expect(page).to have_content('Are you the spouse or dependent child of such a veteran or individual in active duty status?')
end
