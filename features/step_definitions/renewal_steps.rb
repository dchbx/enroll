Then(/(.*) should see active and renewing enrollments/) do |named_person|
  visit "/families/home"
  person = people[named_person]

  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  renewal_effective_date = ce.benefit_sponsorship.renewal_benefit_application.start_on
  effective_date = ce.benefit_sponsorship.active_benefit_application.start_on

  wait_for_condition_until(5) do
    find_all('.hbx-enrollment-panel').count { |n| n.find_all("h3", :text => /Coverage/i).any? } > 1
  end

  expect(page.find_all('.hbx-enrollment-panel').any?{|e|
    (e.find('.label-success').text() == 'Auto Renewing') &&
    (e.find('.enrollment-effective').text() == "Plan Start: " + renewal_effective_date.strftime('%m/%d/%Y'))
  }).to be_truthy

  expect(page.find_all('.hbx-enrollment-panel').any?{|e|
    (e.find('.label-success').text() == 'Coverage Selected') &&
    (e.find('.enrollment-effective').text() == "Plan Start: " + effective_date.strftime('%m/%d/%Y'))
  }).to be_truthy
end

# For new updates
When(/(.*) clicks continue on group selection page for dependents/) do |named_person|
  if find_all('.interaction-click-control-continue').any?
    find('.interaction-click-control-continue', wait: 10).click
  else
    find('.interaction-click-control-shop-for-new-plan', :wait => 10).click
  end
end

When(/(.*) proceed with continue on the group selection page/) do |named_person|
  employer_profile = EmployerProfile.all.first
  plan_year = EmployerProfile.all.first.plan_years.first.start_on.year
  carrier_profile = EmployerProfile.all.first.plan_years.first.benefit_groups.first.reference_plan.carrier_profile
  sic_factors = SicCodeRatingFactorSet.new(active_year: plan_year, default_factor_value: 1.0, carrier_profile: carrier_profile).tap do |factor_set|
    factor_set.rating_factor_entries.new(factor_key: employer_profile.sic_code, factor_value: 1.0)
  end
  sic_factors.save!
  group_size_factors = EmployerGroupSizeRatingFactorSet.new(active_year: plan_year, default_factor_value: 1.0, max_integer_factor_key: 5, carrier_profile: carrier_profile).tap do |factor_set|
    [0..5].each do |size|
      factor_set.rating_factor_entries.new(factor_key: size, factor_value: 1.0)
    end
  end
  group_size_factors.save!
  sleep(1)

  if find_all('.interaction-click-control-continue').any?
    find('.interaction-click-control-continue').click
  else
    find('.interaction-click-control-shop-for-new-plan', :wait => 10).click
  end
end

Then(/(.*) should see \"my account\" page with new enrollment and passive renewal should be canceled/) do |named_person|
  visit "/families/home"

  person = people[named_person]
  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  effective_date = ce.employer_profile.renewing_plan_year.start_on

  expect(page.find_all('.hbx-enrollment-panel').any?{|e|
    (e.find('.label-success').text() == 'Coverage Selected') &&
    (e.find('.enrollment-effective').text() == "Plan Start: " + effective_date.strftime('%m/%d/%Y'))
  }).to be_truthy
  expect(page.find_all('.family-plan-selection').any?{|e| e.find('.status').find('h4').text() == 'Auto Renewing'}).to be_falsey
end

When(/^.+ selects waiver on the plan shopping page$/) do
  click_link 'Waive Coverage'
end

When(/^.+ submits waiver reason$/) do
  waiver_modal = find('#waive_confirm', wait: 10)
  waiver_modal.find('span', text: 'Please select waive reason').click
  waiver_modal.find('#waiver_reason_selection_dropdown').select('I have coverage through Medicaid')
  waiver_modal.find('#waiver_reason_submit', wait: 5).click
end

Then(/^.+ should see waiver summary page$/) do
  expect(page).to have_content 'Waiver confirmation'
end

When(/^.+ clicks continue on waiver summary page/) do
  page.find('.interaction-click-control-continue').click
end

Then("Employee should able to see Waiver tile") do
  find('.interaction-click-control-shop-for-plans', wait: 5)

  expect(page).to have_content 'Waived'
  expect(page).to have_content 'Waived Date'
  expect(page).to have_content 'Reason Waived'
end


Then(/(.+) should see \"my account\" page with waiver and passive renewal should be canceled/) do |named_person|
  sleep 1

  person = people[named_person]
  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  effective_date = ce.employer_profile.renewing_plan_year.start_on


  enrollments = page.all('.hbx-enrollment-panel')
  statuses = enrollments.collect{|e| e.find('.panel-heading').find('.label-success').text()}

  expect(statuses).to include('Waived')
  expect(statuses).to include('Coverage Termination Pending')
  expect(statuses).not_to include('Auto Renewing')
end

When(/^.+ clicks continue on family members page/) do
  page.find('#dependent_buttons').find('.interaction-click-control-continue').click
end
