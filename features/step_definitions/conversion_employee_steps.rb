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

 employee_role = FactoryGirl.create(:employee_role, employer_profile: secondary_employer_profile)
 secondary_employee.update_attributes!(employee_role_id: employee_role.id)

  open_enrollment_start_on = TimeKeeper.date_of_record
  open_enrollment_end_on = open_enrollment_start_on.end_of_month + 13.days
  start_on = open_enrollment_end_on.next_month.beginning_of_month
  end_on = start_on + 1.year - 1.day


  active_plan_year = FactoryGirl.create :plan_year, employer_profile: secondary_employer_profile,
                                                       start_on: start_on - 1.year,
                                                       end_on: end_on - 1.year,
                                                       open_enrollment_start_on: open_enrollment_start_on - 1.year,
                                                       open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days,
                                                       fte_count: 2,
                                                       aasm_state: :published,
                                                       is_conversion: true

  secondary_benefit_group = FactoryGirl.create :benefit_group, plan_year: active_plan_year
  secondary_employee.add_benefit_group_assignment secondary_benefit_group, secondary_benefit_group.start_on

  renewing_plan_year = FactoryGirl.create :plan_year, employer_profile: secondary_employer_profile,
                                             start_on: start_on,
                                             end_on: end_on,
                                             open_enrollment_start_on: open_enrollment_start_on,
                                             open_enrollment_end_on: open_enrollment_end_on,
                                             fte_count: 2,
                                             aasm_state: :renewing_enrolling

  benefit_group = FactoryGirl.create :benefit_group, plan_year: renewing_plan_year, title: 'this is the BGGG'
  secondary_employee.add_renew_benefit_group_assignment benefit_group

  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")

  benefit_group_carrier = benefit_group.reference_plan.carrier_profile
  renewing_carrier = benefit_group.reference_plan.carrier_profile
  [benefit_group_carrier, renewing_carrier].each do |carrier_profile|
    sic_factors = SicCodeRatingFactorSet.new(active_year: 2018, default_factor_value: 1.0, carrier_profile: carrier_profile).tap do |factor_set|
      factor_set.rating_factor_entries.new(factor_key: secondary_employer_profile.sic_code, factor_value: 1.0)
    end
    sic_factors.save!
    group_size_factors = EmployerGroupSizeRatingFactorSet.new(active_year: 2018, default_factor_value: 1.0, max_integer_factor_key: 5, carrier_profile: carrier_profile).tap do |factor_set|
      [0..5].each do |size|
        factor_set.rating_factor_entries.new(factor_key: size, factor_value: 1.0)
      end
    end
    group_size_factors.save!
  end
end

Then(/Employee (.*) should have the (.*) plan year start date as earliest effective date/) do |named_person, plan_year|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  census_employee = employer_profile.census_employees.where(first_name: person[:first_name], last_name: person[:last_name]).first
  bg = plan_year == "renewing" ? census_employee.renewal_benefit_group_assignment.benefit_group : census_employee.active_benefit_group_assignment.benefit_group
  if bg.effective_on_for(census_employee.hired_on) == employer_profile.renewing_plan_year.start_on
  else
    expect(page).to have_content "Raising this failure, b'coz this else block should never be executed"
  end
end

Then(/Employee (.*) should not see earliest effective date on the page/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  expect(page).not_to have_content "coverage starting #{employer_profile.renewing_plan_year.start_on.strftime("%m/%d/%Y")}."
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

  ce.update_attributes(employee_role_id: person_record.employee_roles.first.id)
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

Then(/Employee should see \"You are attempting to purchase coverage through qle proir to your eligibility date\" error message/) do
  screenshot("new_hire_not_yet_eligible_exception")
  find('.alert', text: "You are attempting to purchase coverage through Qualifying Life Event prior to your eligibility date")
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

  employer_profile.renewing_plan_year.update_attributes(:aasm_state => 'renewing_enrolling', open_enrollment_start_on: TimeKeeper.date_of_record.beginning_of_month)
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

Then(/(.*) should get qle effective date as coverage effective date/) do |named_person|
  person = people[named_person]
  effective_on = Person.where(:first_name=> person[:first_name]).first.primary_family.current_sep.effective_on
  find('.coverage_effective_date', text: effective_on.strftime("%m/%d/%Y"))
end

When(/(.+) should see coverage summary page with renewing plan year start date as effective date/) do |named_person|
  step "#{named_person} should get plan year start date as coverage effective date"
  find('.interaction-click-control-confirm').click
end

Then(/(.+) should see coverage summary page with qle effective date/) do |named_person|
  step "#{named_person} should get qle effective date as coverage effective date"
  find('.interaction-click-control-confirm').click
end

Then(/(.*) should see the receipt page with qle effective date as effective date/) do |named_person|
  expect(page).to have_content('Enrollment Submitted')
  step "#{named_person} should get qle effective date as coverage effective date"

  if page.has_link?('CONTINUE')
    click_link "CONTINUE"
  else
    click_link "GO TO MY ACCOUNT"
  end
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
    find('.interaction-click-control-continue').click
  end
end

When(/Employee select a qle date based on expired plan year/) do
  screenshot("past_qle_date")
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 30.days).strftime("%m/%d/%Y")
  within '#qle-date-chose' do
    find('.interaction-click-control-continue').click
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
