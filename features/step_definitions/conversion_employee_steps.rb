Given(/^Multiple Conversion Employers for (.*) exist with active and renewing plan years$/) do |named_person|
  person = people[named_person]
  secondary_organization = FactoryGirl.create :organization, legal_name: person[:mlegal_name],
                                                   dba: person[:mdba],
                                                   fein: person[:mfein]
  secondary_employer_profile = FactoryGirl.create :employer_profile, organization: secondary_organization,
                                                           profile_source:'conversion',
                                                           registered_on: TimeKeeper.date_of_record
  secondary_employee = FactoryGirl.create :census_employee, employer_profile: secondary_employer_profile,
                                                            first_name: person[:first_name],
                                                            last_name: person[:last_name],
                                                            ssn: person[:ssn],
                                                            dob: person[:dob_date]
  open_enrollment_start_on = (TimeKeeper.date_of_record-1.month).end_of_month + 1.day
  open_enrollment_end_on = open_enrollment_start_on.next_month + 12.days
  start_on = open_enrollment_start_on + 2.months
  end_on = start_on + 1.year - 1.day

  secondary_plan_year = FactoryGirl.create :plan_year, employer_profile: secondary_employer_profile,
                                                       start_on: start_on - 1.year - 3.months,
                                                       end_on: (end_on - 1.year - 3.months).end_of_month,
                                                       open_enrollment_start_on: open_enrollment_start_on - 1.year - 3.months,
                                                       open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days - 3.months,
                                                       fte_count: 2,
                                                       aasm_state: :published
  secondary_benefit_group = FactoryGirl.create :benefit_group, plan_year: secondary_plan_year
  secondary_plan_year.expire!

  secondary_employee.add_benefit_group_assignment secondary_benefit_group, secondary_benefit_group.start_on

  plan_year = FactoryGirl.create :plan_year, employer_profile: secondary_employer_profile,
                                             start_on: start_on,
                                             end_on: end_on,
                                             open_enrollment_start_on: open_enrollment_start_on,
                                             open_enrollment_end_on: open_enrollment_end_on,
                                             fte_count: 2,
                                             aasm_state: :renewing_draft
  benefit_group = FactoryGirl.create :benefit_group, plan_year: plan_year,
                                                     title: 'this is the BGGG'
  plan_year.publish!
  secondary_employee.add_renew_benefit_group_assignment benefit_group

  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
end

Then(/Employee (.*) should see renewing plan year start date as earliest effective date/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  find('label', text: "Enroll as an employee of #{employer_profile.legal_name} with coverage starting #{employer_profile.renewing_plan_year.start_on.strftime("%m/%d/%Y")}.")
end

And(/(.*) already matched and logged into employee portal/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  ce = employer_profile.census_employees.where(:first_name => /#{person[:first_name]}/i,
                                               :last_name => /#{person[:last_name]}/i).first
  person_record = FactoryGirl.create(:person_with_employee_role, first_name: person[:first_name],
                                                                 last_name: person[:last_name],
                                                                 ssn: person[:ssn],
                                                                 dob: person[:dob_date],
                                                                 census_employee_id: ce.id,
                                                                 employer_profile_id: employer_profile.id,
                                                                 hired_on: ce.hired_on)
  FactoryGirl.create :family, :with_primary_family_member, person: person_record
  user = FactoryGirl.create(:user, person: person_record,
                                   email: person[:email],
                                   password: person[:password],
                                   password_confirmation: person[:password])
  login_as user
  visit "/families/home"
end

And(/(.*) matches all employee roles to employers and is logged in/) do |named_person|
  person = people[named_person]
  Person.all.select { |stored_person| stored_person["ssn"] == person.ssn &&
                                      stored_person["dob"] == person.dob
                    }
  organizations = Organization.in(fein: [person[:fein], person[:mfein]])
  employer_profiles = organizations.map(&:employer_profile)
  counter = 0
  used_person = nil
  user = nil
  employer_profiles.each do |employer_profile|
    if used_person.nil?
      ce = employer_profile.census_employees.where(:first_name => /#{person[:first_name]}/i,
                                                   :last_name => /#{person[:last_name]}/i).first
      person_record = FactoryGirl.create(:person_with_employee_role, first_name: person[:first_name],
                                                                     last_name: person[:last_name],
                                                                     ssn: person[:ssn],
                                                                     dob: person[:dob_date],
                                                                     census_employee_id: ce.id,
                                                                     employer_profile_id: employer_profile.id,
                                                                     hired_on: ce.hired_on)
      FactoryGirl.create :family, :with_primary_family_member, person: person_record
      user = FactoryGirl.create(:user, person: person_record,
                                       email: person[:email],
                                       password: person[:password],
                                       password_confirmation: person[:password])
      used_person = person_record
    else
      ce = employer_profile.census_employees.where(:first_name => /#{person[:first_name]}/i,
                                                   :last_name => /#{person[:last_name]}/i).first
      used_person.employee_roles.create!(employer_profile_id: employer_profile.id,
                                         ssn: ce.ssn,
                                         dob: ce.dob,
                                         hired_on: ce.hired_on,
                                         census_employee_id: ce.id)
    end
  end
  login_as used_person.user
  expect(used_person.employee_roles.count).to eq(2)
  visit "/families/home"
end

Then(/Employee should see \"employer-sponsored benefits not found\" error message/) do
  screenshot("new_hire_not_yet_eligible_exception")
  find('.alert', text: "Unable to find employer-sponsored benefits for enrollment year")
  visit '/families/home'
end

And(/Employer for (.*) published renewing plan year/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  employer_profile.renewing_plan_year.update_attributes(:aasm_state => 'renewing_published')
end

And(/Employer for (.*) is under open enrollment/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])

  open_enrollment_start_on = TimeKeeper.date_of_record
  open_enrollment_end_on = open_enrollment_start_on.end_of_month + 12.days
  start_on = open_enrollment_start_on.end_of_month + 1.day + 1.month
  end_on = start_on + 1.year - 1.day
  employer_profile.renewing_plan_year.update_attributes(:aasm_state => 'renewing_enrolling', :open_enrollment_start_on => open_enrollment_start_on,
    :open_enrollment_end_on => open_enrollment_end_on, :start_on => start_on, :end_on => end_on)
end

And(/Other Employer for (.*) is also under open enrollment/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:mfein])
  employer_profile.renewing_plan_year.update_attributes(:aasm_state => 'renewing_enrolling', :open_enrollment_start_on => TimeKeeper.date_of_record)
end

When(/Employee clicks on New Hire Badge/) do
  find('#shop_for_employer_sponsored_coverage').click
end

When(/(.*) has New Hire Badges for all employers/) do |named_person|
  expect(page).to have_css('#shop_for_employer_sponsored_coverage', count: 2)
end

When(/(.*) click the first button of new hire badge/) do |named_person|
  person = people[named_person]
  expect(find_all(".alert-notice").first.text).to match person[:legal_name]
  find_all('#shop_for_employer_sponsored_coverage').first.click
end

Then(/(.*) should see the 1st ER name/) do |named_person|
  person = people[named_person]
  expect(page).to have_content(person[:legal_name])
end

Then(/(.*) should see New Hire Badges for 2st ER/) do |named_person|
  person = people[named_person]
  expect(page).to have_content(person[:mlegal_name])
end

When(/2st ER for (.*) published renewing plan year/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:mfein])
  employer_profile.renewing_plan_year.publish!
end

When(/(.*) click the button of new hire badge for 2st ER/) do |named_person|
  #py =Person.last.active_employee_roles.last.census_employee.renewal_benefit_group_assignment.benefit_group.plan_year
  #py.publish!
  find_all('#shop_for_employer_sponsored_coverage').last.click
end

Then(/(.*) should see the 2st ER name/) do |named_person|
  person = people[named_person]
  expect(page).to have_content(person[:mlegal_name])
end

Then(/(.*) should see \"open enrollment not yet started\" error message/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  find('.alert', text: "Open enrollment for your employer-sponsored benefits not yet started. Please return on #{employer_profile.renewing_plan_year.open_enrollment_start_on.strftime("%m/%d/%Y")} to enroll for coverage.")
  visit '/families/home'
end

Then(/(.*) should get plan year start date as coverage effective date/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  find('.coverage_effective_date', text: employer_profile.renewing_plan_year.start_on.strftime("%m/%d/%Y"))
end

When(/(.+) should see coverage summary page with renewing plan year start date as effective date/) do |named_person|
  step "#{named_person} should get plan year start date as coverage effective date"
  find('.interaction-click-control-confirm').click
end

Then(/(.*) should see the receipt page with renewing plan year start date as effective date/) do |named_person|
  expect(page).to have_content('Enrollment Submitted')
  step "#{named_person} should get plan year start date as coverage effective date"

  if page.has_link?('CONTINUE')
    click_link "CONTINUE"
  else
    click_link "GO TO MY ACCOUNT"
  end
end

When(/Employee click the "(.*?)" in qle carousel/) do |qle_event|
  click_link "#{qle_event}"
end

When(/Employee select a past qle date/) do
  expect(page).to have_content "Married"
  screenshot("past_qle_date")
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  within '#qle-date-chose' do
    click_link "CONTINUE"
  end
end

Then(/Employee should see confirmation and clicks continue/) do
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  screenshot("valid_qle")
  click_button "Continue"
end

Then(/Employee should see family members page and clicks continue/) do
  expect(page).to have_content "Household Info: Family Members"
  within '#dependent_buttons' do
    click_link "Continue"
  end
end
