
Given(/^that the user is on the Family Relationships page$/) do
login_as consumer, scope: :user
visit financial_assistance_applications_path
create_plan
click_button "Start new application"
find(".btn", text: "ADD INCOME & COVERAGE INFO").click
	find("#income_from_employer_no").click
	find("#self_employed_no").click
	find("#other_income_no").click
	find("#adjustments_income_no").click
	find("#enrolled_in_coverage_no").click
	find("#access_to_other_coverage_no").click
	find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
	find("#is_required_to_file_taxes_yes").click
	find("#is_claimed_as_tax_dependent_no").click
	find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
	find("#is_pregnant_no").click
	find("#is_post_partum_period_no").click
	find("#is_self_attested_blind_no").click
	find("#has_daily_living_no").click
	find("#has_daily_living_help_no").click
	find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
	page.should have_xpath('//span[@class="complete-icon"]')


	find('.interaction-click-control-add-member').click
	fill_in "dependent_first_name", with: 'johnson'
	fill_in "dependent_last_name", with: 'smith'
	fill_in "family_member_dob_", with: '10/10/1984'
	fill_in "dependent_ssn", with: '123456543'
	find(:xpath, '//label[@for="radio_female"]').click
	find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[2]/p').click
	find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[3]/div/ul/li[7]').click
	find(:xpath, '//label[@for="is_applying_coverage_false"]').click
	find(".btn", text: "CONFIRM MEMBER").click
	expect(page).to have_content('ADD INCOME & COVERAGE INFO')
	find(".btn", text: "ADD INCOME & COVERAGE INFO").click
	find("#income_from_employer_no").click
	find("#self_employed_no").click
	find("#other_income_no").click
	find("#adjustments_income_no").click
	find("#enrolled_in_coverage_no").click
	find("#access_to_other_coverage_no").click
	find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
	find("#is_required_to_file_taxes_yes").click
	find("#is_claimed_as_tax_dependent_no").click
	find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
	find("#is_pregnant_no").click
	find("#is_post_partum_period_no").click
	find("#is_self_attested_blind_no").click
	find("#has_daily_living_no").click
	find("#has_daily_living_help_no").click
	find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
	page.should have_xpath('//span[@class="complete-icon"]')
	find('.btn', text: 'CONTINUE').click
end

When(/^there is no missing relatioships$/) do
  expect(page).to have_content('All the relationships are added. Please continue.')
end

Then(/^the CONTINUE button is enabled$/) do
  page.should have_no_xpath "//a[@disabled]"
end

Then(/^the user will navigate to the Review & Submit page$/) do
  expect(page).to have_content('Review Your Application')
end
