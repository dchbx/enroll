
When(/^login to HBX portal with email: (.*) and password: (.*)$/) do |username,password|
  person = people['Soren White']
  @emple_role =FactoryGirl.create :employee_role
  organization = FactoryGirl.create :organization, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  employer_profile=FactoryGirl.create :employer_profile, organization: organization
  owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
  employee = FactoryGirl.create :census_employee, employer_profile: employer_profile,
  first_name: person[:first_name],
  last_name: person[:last_name],
  ssn: person[:ssn],
  dob: person[:dob_date]

  plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, fte_count: 2, aasm_state: :published
  benefit_group = FactoryGirl.create :benefit_group, plan_year: plan_year
  employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  
  FactoryGirl.create(:person_with_employee_role, first_name: person[:first_name], last_name: person[:last_name], ssn: person[:ssn], dob: person[:dob_date], census_employee_id: ce.id, employer_profile_id: employer_profile.id, hired_on: ce.hired_on)
  person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first
  
  FactoryGirl.create :family, :with_primary_family_member, person: person_rec
  FactoryGirl.create(:household, family: person_rec.primary_family)
  benefit_group_assignment = FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: ce)
  
  FactoryGirl.create(:hbx_enrollment,
    household: person_rec.primary_family.active_household,
    coverage_kind: "health",
    effective_on: benefit_group.start_on,
    enrollment_kind: "open_enrollment",
    kind: "employer_sponsored",
    submitted_at: benefit_group.start_on - 20.days,
    benefit_group_id: benefit_group.id,
    employee_role_id: @emple_role.id,
    benefit_group_assignment_id: benefit_group_assignment.id,
    plan_id: benefit_group.elected_plan_ids.first
    )
  
  visit '/'
  click_link 'HBX Portal'

  find('.interaction-click-control-sign-in-existing-account').click
  find('.interaction-field-control-user-login').set(username)
  find('.interaction-field-control-user-password').set(password)
  click_button 'Sign in'
end

Then(/^admin login's$/) do
expect(page).to have_content('Signed in successfully.')
end

Then(/^Click on (.*) Link$/) do |link_name|
  click_on link_name
end

Then(/^display no records$/) do
  expect(page).to have_content("No employees enrolled.")
end

Then(/^active benefit plan employees displayed$/) do
  expect(page).to have_content("Enrollment Report")
end
