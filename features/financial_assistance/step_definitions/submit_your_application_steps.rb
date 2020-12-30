# frozen_string_literal: true

Given(/^the user is on FAA Household Info: Family Members page$/) do
  login_as consumer, scope: :user
  hbx_profile = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
    ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
    bcp.update_attributes!(slcsp_id: ivl_product.id)
  end
  
  visit help_paying_coverage_insured_consumer_role_index_path
  find('button.interaction-click-control-continue')
  choose('radio1', allow_label_click: true)
  find('button.interaction-click-control-continue').click

  # should be on checklist page now
  find('a.interaction-click-control-continue').click
end

Given(/^all applicants are in Info Completed state with all types of income$/) do
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
    find_all("#job_income .incomes-list .interaction-choice-control-income-frequency-kind span.label").first.click
    find_all("#job_income li.interaction-choice-control-income-frequency-kind-7").first.click
    fill_in 'income[employer_address][address_1]', with: '1 K Street'
    fill_in 'income[employer_address][city]', with: 'Washington'
    fill_in 'income[employer_address][zip]', with: '20000'
    find(:xpath, '//*[@id="new_income"]/div[1]/div[4]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_income"]/div[1]/div[4]/div[2]/div/div[3]/div/ul/li[10]').click
    fill_in 'income[employer_phone][full_phone_number]', with: '7898765676'
    click_button('Save')
    find('#has_self_employment_income_true').click
    fill_in 'income[amount]', with: '100.00'
    find_all("#self_employed_incomes .incomes-list .interaction-choice-control-income-frequency-kind span.label").first.click
    find_all("#self_employed_incomes li.interaction-choice-control-income-frequency-kind-7").first.click
    fill_in 'income[start_on]', with: '01/01/2018'
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find('#has_other_income_true').click
    sleep 1
    find(:css, "#other_income_kind[value='interest']").set(true)
    fill_in 'income[amount]', with: '100'
    fill_in 'income[start_on]', with: '1/1/2018'
    find(".new-other-income-form.interest span.label").click
    find(".new-other-income-form.interest li.interaction-choice-control-income-frequency-kind-7").click
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find('#has_deductions_true').click
    find(:css, "#deduction_kind[value='moving_expenses']").set(true)
    fill_in 'deduction[amount]', with: '50'
    fill_in 'deduction[start_on]', with: '1/1/2018'
    find(".new-deduction-form.moving_expenses span.label").click
    find(".new-deduction-form.moving_expenses li.interaction-choice-control-deduction-frequency-kind-7").click
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find('#has_enrolled_health_coverage_false').click
    find('#has_eligible_health_coverage_false').click


    find(:xpath, '//*[@id="btn-continue"]').click

    find('#is_pregnant_no').click
    find('#is_post_partum_period_no').click
    find('#is_self_attested_blind_no').click
    find('#has_daily_living_no').click
    find('#need_help_paying_bills_no').click
    find('#radio_physically_disabled_no').click
    choose('is_veteran_or_active_military_no')
    find('[name=commit]').click
  end
end

Then(/^the user is on the Submit Your Application page$/) do
  expect(page).to have_content('Submit Your Application')
end

Given(/^a required question is not answered$/) do
  expect(find_all("input[type='checkbox']").any? {|checkbox| !checkbox.checked?}).to be(true)
  expect(false).to eq(find('#living_outside_no').checked?).and eq(find('#living_outside_yes').checked?)
end

Given(/^the user has not signed their name$/) do
  expect(true).to eq(find('#first_name_thank_you').text.empty?).or eq(find('#last_name_thank_you').text.empty?)
end

Then(/^the submit button will be disabled$/) do
  expect(find('.interaction-click-control-submit-application')[:class].include?('disabled')).to be(true)
end

Given(/^all required questions are answered$/) do
  find_all("input[type='checkbox']").each {|checkbox| checkbox.set(true)}
  find('#living_outside_no').set(true)
  find('#application_report_change_terms').click
end

Given(/^the user has signed their name$/) do
  fill_in 'first_name_thank_you', with: application.primary_applicant.first_name
  fill_in 'last_name_thank_you', with: application.primary_applicant.last_name
end

Then(/^the submit button will be enabled$/) do
  expect(find('.interaction-click-control-submit-application')[:class].include?('disabled')).to be(false)
end

Then(/^the user is on the Error Submitting Application page$/) do
  expect(page).to have_content('Error Submitting Application')
end

Given(/^the user clicks SUBMIT$/) do
  find('.interaction-click-control-submit-application').click
end
