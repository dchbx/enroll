And(/^saves a YES answer to the question: Do you want to apply for Medicaid…$/) do
	find(:xpath, '//label[@for="radio1"]').click
	benchmark_plan
	find('.btn', text: 'CONTINUE').click
	expect(page).to have_content('Application Checklist')
end

Given(/^that the user is on the Application Checklist page$/) do
	expect(page).to have_content('Application Checklist')
	find('.btn', text: 'CONTINUE').click
end

Then(/^the user will navigate to the FAA Household Info page$/) do
	expect(page).to have_content('Household Info: Family Members')
end