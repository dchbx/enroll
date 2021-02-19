# frozen_string_literal: true

Given(/^that the user is on FAA Household Info: Family Members page$/) do
  login_as consumer, scope: :user
  hbx_profile = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
    ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
    bcp.update_attributes!(slcsp_id: ivl_product.id)
  end
  visit root_path
  click_link 'Assisted Consumer/Family Portal'
  click_link 'Continue'
  # Security Questions
  step 'the user answers all the VERIFY IDENTITY  questions'
  click_button 'Submit'
  click_link "Continue Application"
  page.all('label').detect { |l| l.text == 'Yes' }.click
  click_button 'CONTINUE'
  click_link 'Continue'
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
  fill_in "applicant_first_name", with: 'johnson'
  fill_in "applicant_last_name", with: 'smith'
  fill_in "family_member_dob_", with: '10/10/1984'
  fill_in "applicant_ssn", with: '123456543'
  find(:xpath, '//label[@for="radio_female"]').click
  #find(:xpath, '//form/div[1]/div[5]/div[2]/label[1]').click
  # Click label
  find('#new_applicant > div.house.col-md-12.col-sm-12.col-xs-12.no-pd > div:nth-child(5) > div.col-md-5.mt18 > label.static_label.label-floatlabel.mt-label').click
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Spouse')]").click

  choose('applicant_us_citizen_true', allow_label_click: true)
  choose('applicant_naturalized_citizen_false', allow_label_click: true)
  choose('indian_tribe_member_no', allow_label_click: true)
  choose('radio_incarcerated_no', allow_label_click: true)

  find(:xpath, '//label[@for="is_applying_coverage_true"]').click

  find(".btn", text: "CONFIRM MEMBER").click

  sleep 2
  expect(page).to have_content('ADD INCOME & COVERAGE INFO', count: 2)
  application.update!(aasm_state: "draft")
end

Then(/^Family Relationships left section WILL display$/) do
  sleep 2
  expect(page).to have_content('Family Relationships')
end

When(/^all applicants are in Info Completed state$/) do
  until find_all(".btn", text: "ADD INCOME & COVERAGE INFO").empty?
    find_all(".btn", text: "ADD INCOME & COVERAGE INFO")[0].click
    # find("#is_required_to_file_taxes_yes").click
    sleep 10
    find("#is_required_to_file_taxes_no", wait: 10).click
    find("#is_claimed_as_tax_dependent_no", wait: 10).click
    find("#is_joint_tax_filing_no", wait: 10).click if page.all("#is_joint_tax_filing_no").present?
    find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click

    find("#has_job_income_false", wait: 10).click
    find("#has_self_employment_income_false", wait: 10).click
    find(:xpath, '//*[@id="btn-continue"]', wait: 10).click

    find("#has_other_income_false", wait: 10).click
    find(:xpath, '//*[@id="btn-continue"]', wait: 10).click
    find("#has_deductions_false", wait: 10).click
    find(:xpath, '//*[@id="btn-continue"]', wait: 10).click

    find("#has_enrolled_health_coverage_false", wait: 10).click
    find("#has_eligible_health_coverage_false", wait: 10).click
    find(:xpath, '//*[@id="btn-continue"]', wait: 10).click

    find("#is_pregnant_no", wait: 10).click
    find("#is_post_partum_period_no", wait: 10).click
    find("#is_self_attested_blind_no", wait: 10).click
    find("#has_daily_living_no", wait: 10).click
    find("#need_help_paying_bills_no", wait: 10).click
    find("#radio_physically_disabled_no", wait: 10).click
    choose('is_veteran_or_active_military_no')
    find('[name=commit]', wait: 10).click
  end
end

And(/^primary applicant completes application and marks they are required to file taxes$/) do
  find("#is_required_to_file_taxes_yes").click
  sleep 1
  find("#is_claimed_as_tax_dependent_no").click
  find("#is_joint_tax_filing_no").click if page.all("#is_joint_tax_filing_no").present?
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
  find("#radio_physically_disabled_no").click
  choose('is_veteran_or_active_military_no')
  find('[name=commit]').click
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
