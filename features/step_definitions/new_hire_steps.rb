Given(/I set the eligibility rule to (.*)/) do |rule|
  offsets = {
    'first of month following or coinciding with date of hire' => 0,
    'first of the month following date of hire' => 1,
    'first of month following 30 days' => 30,
    'first of month following 60 days' => 60
  }

  employer_profile = EmployerProfile.find_by_fein(people['Soren White'][:fein])
  employer_profile.plan_years.published.first.benefit_groups.first.update_attributes({
    'effective_on_kind' => 'first_of_month',
    'effective_on_offset' => offsets[rule]
    })
end

Given(/I reset employee to future enrollment window/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update_attributes({
    :created_at => (TimeKeeper.date_of_record - 15.days),
    :hired_on => TimeKeeper.date_of_record
  })
end

Given(/Employee new hire enrollment window is closed/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update_attributes({
    :created_at => (TimeKeeper.date_of_record - 45.days),
    :hired_on => (TimeKeeper.date_of_record - 45.days)
  })
end

And(/Employee has current hired on date/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record)
end

And(/Employee has past hired on date/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record - 1.year)
end

And(/Employee has future hired on date/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record + 15.days)
end

def expected_effective_on
  employee = Person.where(:first_name => /Soren/i, :last_name => /White/i).first
  employee.active_employee_roles.first.coverage_effective_on
end

Then(/Employee tries to complete purchase of another plan/) do
  step "Employee clicks \"Shop for Plans\" on my account page"
  step "Employee clicks continue on the group selection page"
  step "Employee should see the list of plans"
  step "I should not see any plan which premium is 0"
  step "Employee selects a plan on the plan shopping page"
  step "Employee should see coverage summary page with employer name and plan details"
  step "Employee clicks on Confirm button on the coverage summary page"
  step "Employee should see receipt page with employer name and plan details"
  step "Employee clicks on Continue button on receipt page"
end

When(/(.*) clicks \"Shop for Plans\" on my account page/) do |named_person|
  find('.interaction-click-control-shop-for-plans').click
end

When(/(.*) clicks continue on the group selection page/) do |named_person|
  wait_for_ajax(2,2)
  if find_all('.interaction-click-control-continue', wait: 10).any?
    find('.interaction-click-control-continue').click
  else
    find('.interaction-click-control-shop-for-new-plan', wait: 10).click
  end
end

Then(/(.*) should see (.*) page with employer name and plan details/) do |named_person, page|
  employer_profile = EmployerProfile.find_by_fein(people['Soren White'][:fein])
  find('p', text: employer_profile.legal_name)
  find('.coverage_effective_date', text: expected_effective_on.strftime("%m/%d/%Y"))
end

When(/(.*) clicks on Continue button on receipt page/) do |named_person|
  find('.interaction-click-control-continue').click
end

Then(/(.*) should see \"my account\" page with enrollment/) do |named_person|
  sleep 1 #wait for e-mail nonsense
  enrollment = first('.hbx-enrollment-panel')
  enrollment.find('.enrollment-effective', text: expected_effective_on.strftime("%m/%d/%Y"))
  # Timekeeper is probably UTC in this case, as we are in a test environment
  # this will cause arbitrary problems with the specs late at night.
#  enrollment.find('.enrollment-created-at', text: TimeKeeper.date_of_record.strftime("%m/%d/%Y"))
end

Then(/Employee should see \"not yet eligible\" error message/) do
  screenshot("new_hire_not_yet_eligible_exception")
  wait_for_ajax(2,2)
  expect(page).to have_content("You're not yet eligible under your employer-sponsored benefits. Please return on #{TimeKeeper.date_of_record + 15.days} to enroll for coverage.")
  visit '/families/home'
end

Then(/Employee should see \"may not enroll until eligible\" error message/) do
  screenshot("new_hire_not_eligible_exception")
  find('.alert', text: "You may not enroll until you're eligible under an enrollment period.")
  visit '/families/home'
end

When(/Employee enters Qualifying Life Event/) do
  wait_for_ajax
  first("#carousel-qles a").click
  expect(page).to have_content "Married"
  screenshot("future_qle_date")
  wait_for_ajax
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  click_link "CONTINUE"
  click_button "Continue"
end

When(/Employee clicks continue on the family members page/) do
  click_link('btn_household_continue')
  wait_for_ajax
end
