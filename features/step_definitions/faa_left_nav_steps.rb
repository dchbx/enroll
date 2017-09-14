Given(/^that an FA application is in the draft state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  benchmark_plan
  click_button "Start new application"
end

Given(/^the user is on the FAA Household Info: Family Members page$/) do
  consumer.person.families.last.family_members.each do |family_member|
    expect(page).to have_content(family_member.first_name)
  end
end

Given(/^the left column will present the following sections Financial Assistance, Household Info & Review & Submit$/) do
  find_link('Financial Applications').visible?
  find_link('Household Info').visible?
  find_link('Review and Submit').visible?
end

When(/^the user clicks the Financial Applications link in left nav$/) do
  find(:xpath,'//*[@id="left-navigation"]/li[1]/a').click
end

Then(/^the user will navigate to the household's Application Index page$/) do
  expect(page).to have_content('Your Financial Asistance Applications')
end

When(/^the user clicks the Household Info link in left nav$/) do
  find(:xpath,'//*[@id="left-navigation"]/li[2]/a').click
end

Then(/^the user will navigate to the household's info page$/) do
  expect(page).to have_content('Household Info')
end

When(/^the user clicks the Review & Submit link in left nav$/) do
  find('.interaction-click-control-review-and-submit').click
end

Then(/^the user will NOT navigate due to the link being disabled\.$/) do
  expect(page).to have_content('Household Info: Family Members')
  consumer.person.families.last.family_members.each do |family_member|
    expect(page).to have_content(family_member.first_name)
  end
end

When(/^at least one applicant is in the In Progress state$/) do
  expect(application.incomplete_applicants?).to be true
  expect(page).to have_content('Info Needed')
end

When(/^all member to member relationships are NOT nil$/) do
  expect(application.family.relationships_complete?).to eq(true)
end

Then(/^the user will navigate into the first incomplete applicant's Income & Coverage page$/) do
  expect(page).to have_content('Income and Coverage')
end

When(/^the user completes application$/) do
  find('.btn', text: 'CONTINUE').click
  choose('income_from_employer_no')
  choose('self_employed_no')
  choose('other_income_no')
  choose('adjustments_income_no')
  choose('enrolled_in_coverage_no')
  choose('access_to_other_coverage_no')
  find('.interaction-click-control-continue').click
  choose('is_required_to_file_taxes_yes')
  choose('is_claimed_as_tax_dependent_no')
  find('.interaction-click-control-continue').click
  choose('is_pregnant_no')
  choose('is_post_partum_period_no')
  page.execute_script("$('#pregnancy_end_on').val('11/11/2017')")
  find("#is_self_attested_blind_no").trigger('click')
  choose('has_daily_living_no')
  choose('has_daily_living_help_no')
  find('.interaction-click-control-continue').click
end

When(/^now add two more members to the family with at least one relationship as Unrelated$/) do
  find('.interaction-click-control-add-member').click
  fill_in "dependent_first_name", with: 'johnson'
  fill_in "dependent_last_name", with: 'smith'
  fill_in "family_member_dob_", with: '10/10/1984'
  fill_in "dependent_ssn", with: '123456543'
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[2]/p').click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[3]/div/ul/li[7]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click

  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  find(:xpath, '//label[@for="radio_physically_disabled_no"]').click
  find('#add_info_buttons_ > span').click

  if page.has_link?('ADD INCOME & COVERAGE INFO')
    click_link 'ADD INCOME & COVERAGE INFO'
  elsif page.has_link?('EDIT INCOME & COVERAGE INFO')
    click_link 'EDIT INCOME & COVERAGE INFO'
  end

  choose('income_from_employer_no')
  choose('self_employed_no')
  choose('other_income_no')
  choose('adjustments_income_no')
  choose('enrolled_in_coverage_no')
  choose('access_to_other_coverage_no')
  find('.interaction-click-control-continue').click
  choose('is_required_to_file_taxes_yes')
  choose('is_claimed_as_tax_dependent_no')
  find('.interaction-click-control-continue').click
  choose('is_pregnant_no')
  choose('is_post_partum_period_no')
  page.execute_script("$('#pregnancy_end_on').val('11/11/2017')")
  find("#is_self_attested_blind_no").trigger('click')
  choose('has_daily_living_no')
  choose('has_daily_living_help_no')
  find('.interaction-click-control-continue').click


  find('.interaction-click-control-add-member').click
  fill_in "dependent_first_name", with: 'Jackson'
  fill_in "dependent_last_name", with: 'lee'
  fill_in "family_member_dob_", with: '10/10/1990'
  fill_in "dependent_ssn", with: '123456333'
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[2]/p').click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[3]/div/ul/li[5]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click

  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  find(:xpath, '//label[@for="radio_physically_disabled_no"]').click
  find('#add_info_buttons_ > span').click

  if page.has_link?('ADD INCOME & COVERAGE INFO')
    click_link 'ADD INCOME & COVERAGE INFO'
  elsif page.has_link?('EDIT INCOME & COVERAGE INFO')
    click_link 'EDIT INCOME & COVERAGE INFO'
  end

  choose('income_from_employer_no')
  choose('self_employed_no')
  choose('other_income_no')
  choose('adjustments_income_no')
  choose('enrolled_in_coverage_no')
  choose('access_to_other_coverage_no')
  find('.interaction-click-control-continue').click
  choose('is_required_to_file_taxes_yes')
  choose('is_claimed_as_tax_dependent_no')
  find('.interaction-click-control-continue').click
  choose('is_pregnant_no')
  choose('is_post_partum_period_no')
  page.execute_script("$('#pregnancy_end_on').val('11/11/2017')")
  find("#is_self_attested_blind_no").trigger('click')
  choose('has_daily_living_no')
  choose('has_daily_living_help_no')
  find('.interaction-click-control-continue').click
end

When(/^user clicks Previous link$/) do
  find('.interaction-click-control-previous').trigger 'click'
end

When(/^all applicants are in a COMPLETED state$/) do
  expect(page).to have_content('Info Complete')
end

When(/^at least one member to member relationships is NIL$/) do
  people_ids = application.family.primary_applicant.person.person_relationships.map(&:successor_id)
  add_family_members(people_ids, application.family)
  expect(application.family.relationships_complete?).to be false
end

Then(/^the user will navigate to Household Relationships page$/) do
  expect(page).to have_content('Household Relationships')
end
