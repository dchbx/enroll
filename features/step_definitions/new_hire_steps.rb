Given(/^I set the eligibility rule to (.*)/) do |rule|
  offsets = {
    'first of month following or coinciding with date of hire' => 0,
    'first of the month following date of hire' => 1,
    'first of month following 30 days' => 30,
    'first of month following 60 days' => 60
  }

  employer_profile = EmployerProfile.find_by_fein(people['Soren White'][:fein])
  employer_profile.plan_years.each do |py|
    py.benefit_groups.each do |bg|
      bg.update_attributes({
        'effective_on_kind' => 'first_of_month',
        'effective_on_offset' => offsets[rule]
        })
    end
  end
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
  CensusEmployee.where(:first_name => /Soren/i,
                       :last_name => /White/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record)
end

And(/Current hired on date all employments/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).each do |census_employee|
    census_employee.update_attributes(:hired_on => TimeKeeper.date_of_record)
  end
end

And(/Employee has past hired on date/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record - 1.year)
end

And(/Employee has future hired on date/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record + 15.days)
end

def expected_effective_on(qle: false)
  person = Person.where(:first_name => /Soren/i, :last_name => /White/i).first
  if qle
    person.primary_family.current_sep.effective_on
  else
    person.active_employee_roles.first.coverage_effective_on
  end
end

Then(/Employee tries to complete purchase of another plan/) do
  step "I can click Shop for Plans button"
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
    find('.interaction-click-control-shop-for-new-plan', :wait => 10).click
  end
end

Then(/^I can click Shop for Plans button$/) do
  click_button "Shop for Plans"
end

And(/Employer for (.*) has (.*) rule/) do |named_person, rule|
  employer_profile = EmployerProfile.find_by_fein(people[named_person][:fein])
  employer_profile.plan_years.each do |plan_year|
    plan_year.benefit_groups.each{|bg| bg.update_attributes(effective_on_kind: rule) }
  end
end

Then(/(.*) should see (.*) page with employer name and plan details/) do |named_person, page|
  employer_profile = EmployerProfile.find_by_fein(people['Soren White'][:fein])
  find('p', text: employer_profile.legal_name)
  find('.coverage_effective_date', text: expected_effective_on.strftime("%m/%d/%Y"))
end

When(/(.*) clicks back to my account button/) do |named_person|
  find('.interaction-click-control-go-to-my-account').click
end

When(/(.*) clicks on Continue button on receipt page/) do |named_person|
  find('.interaction-click-control-continue').click
end

Then(/(.*) should see \"my account\" page with enrollment/) do |named_person|
  sleep 1 #wait for e-mail nonsense
  enrollments = Person.where(first_name: people[named_person][:first_name]).first.try(:primary_family).try(:active_household).try(:hbx_enrollments) if people[named_person].present?
  sep_enr = enrollments.order_by(:'created_at'.asc).detect{|e| e.enrollment_kind == "special_enrollment"} if enrollments.present?
  enrollment = all('.hbx-enrollment-panel')
  qle  = sep_enr ? true : false

  expect(all('.hbx-enrollment-panel').select{|panel|
    panel.has_selector?('.enrollment-effective', text: expected_effective_on(qle: qle).strftime("%m/%d/%Y"))
  }.present?).to be_truthy

  # Timekeeper is probably UTC in this case, as we are in a test environment
  # this will cause arbitrary problems with the specs late at night.
  #  enrollment.find('.enrollment-created-at', text: TimeKeeper.date_of_record.strftime("%m/%d/%Y"))
end


Then(/(.*) should see \"my account\" page with active enrollment/) do |named_person|
  sleep 1 #wait for e-mail nonsense
  enrollments = Person.where(first_name: people[named_person][:first_name]).first.try(:primary_family).try(:active_household).try(:hbx_enrollments) if people[named_person].present?
  sep_enr = enrollments.order_by(:'created_at'.desc).first.enrollment_kind == "special_enrollment" if enrollments.present?

  enrollment = page.all('.hbx-enrollment-panel')[1]
  qle  = sep_enr ? true : false
  enrollment.find('.panel-heading', text: 'Coverage Selected')
end

Then (/(.*) should see passive renewal/) do |named_person|
  renewal_start = EmployerProfile.find_by_fein(people[named_person][:fein]).renewing_plan_year.start_on.strftime("%m/%d/%Y")
  renewal = page.all('.hbx-enrollment-panel').detect{|e| e.find('.enrollment-effective').text.match(renewal_start)}

  expect(renewal.present?).to be_truthy
  expect(renewal.find('.panel-heading .text-right').text).to eq "Coverage Selected"
end

Then(/(.*) click on make changes button on passive renewal/) do |named_person|
  find_all('.interaction-click-control-make-changes')[0].click
end

Then(/Employee (.*) should see confirm your plan selection page/) do |named_person|
  expect(page).to have_content "Confirm Your Plan Selection"
end

Then (/(.*) should see renewal policy in active status/) do |named_person|
  enrollment = page.all('.hbx-enrollment-panel').first
  enrollment.find('.panel-heading', text: 'Coverage Selected')
end


Then(/(.*) should see active enrollment with his daughter/) do |named_person|
  sleep 1 #wait for e-mail nonsense
  enrollment = page.all('.hbx-enrollment-panel').detect{|e| e.find('.panel-heading .text-right').text == 'Coverage Selected' }

  expect(enrollment.find('.family-members')).to have_content 'Soren'
  expect(enrollment.find('.family-members')).to have_content 'Cynthia'
end

Then(/(.*) should see updated renewal with his daughter/) do |named_person|
  renewal_start = EmployerProfile.find_by_fein(people[named_person][:fein]).renewing_plan_year.start_on.strftime("%m/%d/%Y")

  renewal = page.all('.hbx-enrollment-panel').detect{|e| e.find('.enrollment-effective').text.match(renewal_start)}
  expect(renewal.present?).to be_truthy
  expect(renewal.find('.panel-heading .text-right').text).to eq "Coverage Selected"

  expect(renewal.find('.family-members')).to have_content 'Soren'
  expect(renewal.find('.family-members')).to have_content 'Cynthia'
end

Then(/(.*) selects make changes on active enrollment/) do |named_person|
  enrollment = page.all('.hbx-enrollment-panel').detect{|e| e.find('.panel-heading .text-right').text == 'Coverage Selected' }
  enrollment.find('.interaction-click-control-make-changes').click
end

Then(/(.*) should see page with SelectPlanToTerminate button/) do |named_person|
  sleep(1)
  expect(page).to have_content('Choose Coverage for your Household')
  expect(page.find('.interaction-click-control-select-plan-to-terminate')).to be_truthy
end

When(/(.*) clicks SelectPlanToTerminate button/) do |named_person|
  page.find('.interaction-click-control-select-plan-to-terminate').click
end

Then(/(.*) selects active enrollment for termination/) do |named_person|
  sleep(1)
  page.find('.interaction-click-control-terminate-plan').click
end

When(/(.*) enters termination reason/) do |named_person|
  wait_for_ajax

  waiver_modal = find('.terminate_confirm')
  waiver_modal.find(:xpath, "//div[contains(@class, 'selectric')][p[contains(text(), 'Please select terminate reason')]]").click
  waiver_modal.find(:xpath, "//div[contains(@class, 'selectric-scroll')]/ul/li[contains(text(), 'I do not have other coverage')]").click
  waiver_modal.find('.terminate_reason_submit').click
end

Then(/(.*) should see termination confirmation/) do |named_person|
  sleep(1)
  expect(page).to have_content('Confirm Your Plan Selection')
  page.find('.interaction-click-control-terminate-plan').click
end

Then(/(.*) should see a waiver instead of passive renewal/) do |named_person|
  sleep(1)
  waiver = page.all('.hbx-enrollment-panel').detect{|e| e.find('.panel-heading .text-right').text == 'Waived' }
  expect(waiver.present?).to be_truthy
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
  screenshot("completing SEP")
end

When(/Employee clicks continue on the family members page/) do
  click_link('btn_household_continue')
  wait_for_ajax
end

And(/Employee has past created at date/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update({ :created_at => TimeKeeper.date_of_record - 1.year })
end
