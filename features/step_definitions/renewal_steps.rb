And(/(.*) has active coverage and passive renewal/) do |named_person|
  person = people[named_person]

  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first

  benefit_group = ce.active_benefit_group_assignment.benefit_group
  FactoryGirl.create(:hbx_enrollment,
    household: person_rec.primary_family.active_household,
    coverage_kind: "health",
    effective_on: benefit_group.start_on,
    enrollment_kind: "open_enrollment",
    kind: "employer_sponsored",
    submitted_at: benefit_group.start_on - 20.days,
    benefit_group_id: benefit_group.id,
    employee_role_id: person_rec.active_employee_roles.first.id,
    benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
    plan_id: benefit_group.elected_plan_ids.first
    )

  factory = Factories::FamilyEnrollmentRenewalFactory.new
  factory.family = person_rec.primary_family
  factory.census_employee = ce
  factory.employer = ce.employer_profile
  factory.renewing_plan_year = ce.employer_profile.renewing_plan_year
  factory.renew
end

Then(/(.*) should see active and renewing enrollments/) do |named_person|
  visit "/families/home"

  person = people[named_person]
  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  effective_date = ce.employer_profile.renewing_plan_year.start_on
  expect(page.find_all('.hbx-enrollment-panel').any?{|e|
    (e.find('.label-success').text() == 'Auto Renewing') &&
    (e.find('.enrollment-effective').text() == "Effective date: " + effective_date.strftime('%m/%d/%Y'))
  }).to be_truthy

  expect(page.find_all('.hbx-enrollment-panel').any?{|e|
    (e.find('.label-success').text() == 'Coverage Selected') &&
    (e.find('.enrollment-effective').text() == "Effective date: " + (effective_date - 1.year).strftime('%m/%d/%Y'))
  }).to be_truthy
end

When(/(.*) proceed with continue on the group selection page/) do |named_person|
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
    (e.find('.enrollment-effective').text() == "Effective date: " + effective_date.strftime('%m/%d/%Y'))
  }).to be_truthy

  expect(page.find_all('.family-plan-selection').any?{|e| e.find('.status').find('h4').text() == 'Auto Renewing'}).to be_falsey
end
