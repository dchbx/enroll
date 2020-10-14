Given(/^(.*) eligibility rule has been set to (.*)?/) do |legal_name, rule|
  offsets = {
    'first of month following or coinciding with date of hire' => 0,
    'first of the month following date of hire' => 1,
    'first of month following 30 days' => 30,
    'first of month following 60 days' => 60
  }

  employer_profile = employer_profile(legal_name)
  sponsorship = employer_profile.active_benefit_sponsorship
  sponsorship.benefit_applications.each do |benefit_application|
    benefit_application.benefit_packages.each do |benefit_package|
      benefit_package.probation_period_kind = :first_of_month
    end
  end
  sponsorship.save!
end

Given(/I reset employee to future enrollment window/) do
  CensusEmployee.where(:first_name => /Patrick/i, :last_name => /Doe/i).first.update_attributes({
    :created_at => (TimeKeeper.date_of_record - 15.days),
    :hired_on => TimeKeeper.date_of_record
  })
end

Given(/Employee new hire enrollment window is closed/) do
  CensusEmployee.where(:first_name => /Patrick/i, :last_name => /Doe/i).first.update_attributes({
    :created_at => (TimeKeeper.date_of_record - 45.days),
    :hired_on => (TimeKeeper.date_of_record - 45.days)
  })
end

And(/Employee has current hired on date/) do
  CensusEmployee.where(:first_name => /Patrick/i,
                       :last_name => /Doe/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record)
end

And(/Current hired on date all employments/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).each do |census_employee|
    census_employee.update_attributes(:hired_on => TimeKeeper.date_of_record)
  end
end

And(/^census employee records for (.*?) have current hired on date for each employers$/) do |named_person|
  person = people[named_person]
  census_employees = CensusEmployee.where(:first_name => person[:first_name], :last_name => person[:last_name]).to_a
  census_employees.each do |census_employee|
    census_employee.update_attributes(:hired_on => TimeKeeper.date_of_record)
  end
end

And(/Employee has past hired on date/) do
  CensusEmployee.where(:first_name => /Patrick/i, :last_name => /Doe/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record - 1.year)
end

And(/Employee has future hired on date/) do
  CensusEmployee.where(:first_name => /Patrick/i, :last_name => /Doe/i).first.update_attributes(:hired_on => TimeKeeper.date_of_record + 15.days)
end

def expected_effective_on(qle: false)
  person = Person.where(:first_name => /Patrick/i, :last_name => /Doe/i).first
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
  step "Employee selects a plan on the plan shopping page"
  step "Employee should see coverage summary page with employer name and plan details"
  step "Employee clicks on Confirm button on the coverage summary page"
  step "Employee should see receipt page with employer name and plan details"
  step "Employee clicks on Continue button on receipt page"
end

When(/(.*) clicks \"Shop for Plans\" on my account page/) do |named_person|
  find('.interaction-click-control-shop-for-plans', wait: 10).click
end

When(/^Employee clicks continue button on group selection page for dependents$/) do
  if find_all('.interaction-click-control-continue', wait: 10).any?
    find('.interaction-click-control-continue').click
  else
    find('.interaction-click-control-shop-for-new-plan', :wait => 10).click
  end
end

When(/(.*) clicks continue on the group selection page/) do |named_person|
  find_all('.interaction-click-control-continue,.interaction-click-control-shop-for-new-plan', wait: 10).first.click
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
  find('p', text: employer("Acme Inc.").legal_name, wait: 10)
  find('.coverage_effective_date', text: expected_effective_on.strftime("%m/%d/%Y"))
end

When(/(.*) clicks back to my account button/) do |named_person|
  find('.interaction-click-control-go-to-my-account').click
end

When(/(.*) clicks on Continue button on receipt page/) do |named_person|
  find('.interaction-click-control-continue', wait: 10).click
end

Then(/(.*) should see enrollment on my account page/) do |named_person|
  find('.hbx-enrollment-panel .heading-text', wait: 5)
  expect(page).to have_content(named_person)
  exchange_date = TimeKeeper.date_according_to_exchange_at(Time.current)
  expect(page).to have_content("Plan Selected: #{exchange_date.strftime("%m/%d/%Y")}")
end

Then(/(.*) should see \"my account\" page with enrollment/) do |named_person|
  sleep 1 #wait for e-mail nonsense
  enrollments = Person.where(first_name: people[named_person][:first_name]).first.try(:primary_family).try(:active_household).try(:hbx_enrollments) if people[named_person].present?
  sep_enr = enrollments.order_by(:'created_at'.asc).detect{|e| e.enrollment_kind == "special_enrollment"} if enrollments.present?
  enrollment = find_all('.hbx-enrollment-panel', wait: 10)
  qle  = sep_enr ? true : false
  wait_for_condition_until(5) do
    enrollment_selection_badges.count > 0
  end
  expect(enrollment_selection_badges.any? { |n| n.find_all('.enrollment-effective', text: expected_effective_on(qle: qle).strftime("%m/%d/%Y")).any? }).to be_truthy

  expect(all('.hbx-enrollment-panel').select{|panel|
    panel.has_selector?('.enrollment-effective', text: expected_effective_on(qle: qle).strftime("%m/%d/%Y"))
  }.present?).to be_truthy

  # Timekeeper is probably UTC in this case, as we are in a test environment
  # this will cause arbitrary problems with the specs late at night.
  exchange_date = TimeKeeper.date_according_to_exchange_at(Time.current)
  enrollment[0].find('.enrollment-created-at', text: exchange_date.strftime("%m/%d/%Y"))
end


Then(/(.*) should see \"my account\" page with active enrollment/) do |named_person|
  sleep 3 #wait for e-mail nonsense
  enrollments = Person.where(first_name: people[named_person][:first_name]).first.try(:primary_family).try(:hbx_enrollments) if people[named_person].present?
  sep_enr = enrollments.order_by(:'created_at'.desc).first.enrollment_kind == "special_enrollment" if enrollments.present?
  enrollment = page.all('.hbx-enrollment-panel')[1]
  qle  = sep_enr ? true : false
  enrollment.find('.panel-heading', text: 'Coverage Selected')
end

Then (/(.*) should see passive renewal/) do |named_person|
  renewal_start = benefit_sponsorship.renewal_benefit_application.start_on
  renewal = page.all('.hbx-enrollment-panel').detect{|e| e.find('.enrollment-effective').text.match(renewal_start.to_s)}

  expect(renewal.present?).to be_truthy
  expect(renewal.find('.panel-heading .text-right').text).to eq "Auto Renewing"
end

Then(/(.*) click on make changes button on passive renewal/) do |named_person|
  find_all('.interaction-click-control-make-changes')[0].click
end

Then(/Employee (.*) should see confirm your plan selection page/) do |named_person|
  find('.interaction-click-control-confirm', wait: 5)
  expect(page).to have_content "Confirm Your Plan Selection"
end

Then (/(.*) should see renewal policy in active status/) do |named_person|
  enrollment = page.all('.hbx-enrollment-panel').first
  enrollment.find('.panel-heading', text: 'Coverage Selected')
end

Then(/(.*) should see active enrollment with their spouse/) do |named_person|
  sleep 1 #wait for e-mail nonsense
  enrollment = page.all('.hbx-enrollment-panel').detect{|e| e.find('.panel-heading .text-right').text == 'Coverage Selected' }

  expect(enrollment.find('.family-members')).to have_content 'Cynthia'
  sleep 5
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
  enrollment = find_all('.hbx-enrollment-panel', wait: 10).detect{|e| e.find('.panel-heading .text-right').text == 'Coverage Selected' }
  enrollment.find('.interaction-click-control-make-changes').click
end

Then(/(.*) should see page with SelectPlanToTerminate button/) do |named_person|
  find('.interaction-click-control-select-plan-to-terminate', wait: 10)
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
  within('.terminate_confirm .modal-dialog') do
    find('p', text: 'Please select terminate reason').click
    within all('.selectric-scroll').last do
      find('li', text: 'I have coverage through Medicaid').click
    end
   find('.terminate_reason_submit').click
  end
end

When(/(.*) enters reason for termination in modal$/) do |named_person|
  wait_for_ajax
  select_waiver_select = page.find("#waiver_reason_selection_dropdown")
  select_waiver_select.trigger('click')
  # Medicaid option
  find("option[value='I have coverage through Medicaid']").trigger('click')
  first_select_option = find("#waiver_reason_selection_dropdown > option:nth-child(7)").text
  select(first_select_option, :from => "waiver_reason_selection_dropdown")
  wait_for_ajax
  inputs = page.all('input')
  terminate_reason_submit = inputs.detect { |input| input[:id] == "waiver_reason_submit" }
  terminate_reason_submit.trigger('click')
end

When(/^.+ submits termination reason in modal$/) do
  waiver_modal = find('.terminate_confirm')
  find('.selectric', text: 'Please select terminate reason').click
  find('li', :text => 'I have coverage through Medicare').click
  waiver_modal.find('.terminate_reason_submit').click
end

Then(/(.*) should see a confirmation message of (.*)$/) do |named_person, message|
  expect(page).to have_content(message)
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
  find('#btn-continue', wait: 10).click
  find('h1', text: 'Choose Coverage for your Household', wait: 10)
  find('#btn-continue', wait: 10).click
  find('.alert', wait: 10)
  expect(page).to have_content("You're not yet eligible under your employer-sponsored benefits. Please return on #{(TimeKeeper.date_of_record + 15.days).strftime('%m/%d/%Y')} to enroll for coverage.")
  visit '/families/home'
end

Then(/Employee should see \"may not enroll until eligible\" error message/) do
  screenshot("new_hire_not_eligible_exception")
  find('.alert', text: "You may not enroll unless it’s open enrollment or you’re eligible for a special enrollment period.")
  visit '/families/home'
end

When(/Employee enters Qualifying Life Event/) do
  wait_for_ajax
  find_all("#carousel-qles a", wait: 10).first.click
  expect(page).to have_content "Married"
  screenshot("future_qle_date")
  wait_for_ajax
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  find('#qle_submit', wait: 10).click
  find('input.interaction-click-control-continue', wait: 10, visible: false).click
  screenshot("completing SEP")
end

When(/Employee clicks continue on the family members page/) do
  click_link('btn_household_continue')
  wait_for_ajax
end

When(/(.*) clicks shop for new plan on the group selection page/) do |_named_person|
  find('.interaction-click-control-shop-for-new-plan', wait: 10).click
end

Then(/Employee should see not yet eligible error message/) do
  find('h1', text: 'Choose Coverage for your Household', wait: 10)
  find('.alert', wait: 10)
  expect(page).to have_content("You're not yet eligible under your employer-sponsored benefits. Please return on #{(TimeKeeper.date_of_record + 15.days).strftime('%m/%d/%Y')} to enroll for coverage.")
  visit '/families/home'
end

And(/Employee has past created at date/) do
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update({ :created_at => TimeKeeper.date_of_record - 1.year })
end
