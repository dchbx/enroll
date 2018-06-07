
Given(/^that the user is on FAA Household Info: Family Members page$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  assign_benchmark_plan_id(application)
  click_button "Start new application"
end

When(/^at least one applicant is in the Info Needed state$/) do
  expect(application.incomplete_applicants?).to be true
  expect(page).to have_content('Info Needed')
end

Then(/^the CONTINUE button will be disabled$/) do
  if page.find('#btn-continue')[:disabled] 
    expect(page.find('#btn-continue')[:disabled]).to include("disabled")
  else
    expect(page.find('#btn-continue')[:class]).to include("disabled")
  end
end

Given(/^the primary member exists$/) do
  expect(page).to have_content('SELF')
end

Given(/^NO other household members exist$/) do
  expect(application.active_applicants.count).to eq(1)
end

Then(/^Family Relationships left section will NOT display$/) do
  expect(page).to have_no_content('Family Relationships')
end

Given(/^at least one other household members exist$/) do
  click_link "Add New Person"
  fill_in "dependent_first_name", with: 'johnson'
  fill_in "dependent_last_name", with: 'smith'
  fill_in "family_member_dob_", with: '10/10/1984'
  fill_in "dependent_ssn", with: '123456543'
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '/html/body/div[2]/div[2]/div/div[2]/div[1]/div[5]/ul/li/div/form/div[1]/div[5]/div[2]/div[2]/div/div[2]/p').click
  find(:xpath, '/html/body/div[2]/div[2]/div/div[2]/div[1]/div[5]/ul/li/div/form/div[1]/div[5]/div[2]/div[2]/div/div[3]/div/ul/li[7]').click
  find(:xpath, '//label[@for="is_applying_coverage_false"]').click
  find(".btn", text: "CONFIRM MEMBER").click
  

  expect(page).to have_content('ADD INCOME & COVERAGE INFO', count: 2)
end

Then(/^Family Relationships left section WILL display$/) do
  expect(page).to have_content('Family Relationships')
end

When(/^all applicants are in Info Completed state$/) do
  while find_all(".btn", text: "ADD INCOME & COVERAGE INFO").length > 0 do  
    find_all(".btn", text: "ADD INCOME & COVERAGE INFO")[0].click
    find("#is_required_to_file_taxes_yes").click
    find("#is_claimed_as_tax_dependent_no").click
    find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
      
    find("#has_job_income_false").click
    find("#has_self_employment_income_false").click
    find(:xpath, '//*[@id="btn-continue"]').click
  
    find("#has_other_income_false").click
    find(:xpath, '//*[@id="btn-continue"]').click
  
    find("#has_deductions_false").click
    find(:xpath, '//*[@id="btn-continue"]').click
  
    find("#has_enrolled_health_coverage_false").click
    find("#has_eligible_health_coverage_false").click
    find(:xpath, '//*[@id="btn-continue"]').click
  
    find("#is_pregnant_no").click
    find("#is_post_partum_period_no").click
    find("#is_self_attested_blind_no").click
    find("#has_daily_living_no").click
    find("#need_help_paying_bills_no").click
    find('[name=commit]').click       
  end
end

Then(/^the CONTINUE button will be ENABLED$/) do
  expect(page.find('#btn-continue')[:class]).not_to include("disabled")
end

When(/^user clicks CONTINUE$/) do
  find(".btn", text: "CONTINUE").click
end

Then(/^the user will navigate to Family Relationships page$/) do
  expect(page).to have_content('Family Relationships')
end
