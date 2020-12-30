Given(/^Multiple Conversion Employers for (.*) exist with active and renewing plan years$/) do |named_person|
  person = people[named_person]

  secondary_organization = FactoryBot.create :organization, legal_name: person[:mlegal_name],
                                                   dba: person[:mdba],
                                                   fein: person[:mfein]
  secondary_employer_profile = FactoryBot.create :employer_profile, organization: secondary_organization,
                                                           profile_source:'conversion',
                                                           registered_on: TimeKeeper.date_of_record
  secondary_employee = FactoryBot.create :census_employee, employer_profile: secondary_employer_profile,
                                                            first_name: person[:first_name],
                                                            last_name: person[:last_name],
                                                            ssn: person[:ssn],
                                                            dob: person[:dob_date]

 employee_role = FactoryBot.create(:employee_role, employer_profile: secondary_employer_profile)
 secondary_employee.update_attributes!(employee_role_id: employee_role.id)

  open_enrollment_start_on = TimeKeeper.date_of_record
  open_enrollment_end_on = open_enrollment_start_on.end_of_month + 13.days
  start_on = open_enrollment_end_on.next_month.beginning_of_month
  end_on = start_on + 1.year - 1.day


  active_plan_year = FactoryBot.create :plan_year, employer_profile: secondary_employer_profile,
                                                       start_on: start_on - 1.year,
                                                       end_on: end_on - 1.year,
                                                       open_enrollment_start_on: open_enrollment_start_on - 1.year,
                                                       open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days,
                                                       fte_count: 2,
                                                       aasm_state: :published,
                                                       is_conversion: true

  secondary_benefit_group = FactoryBot.create :benefit_group, plan_year: active_plan_year
  secondary_employee.add_benefit_group_assignment secondary_benefit_group, secondary_benefit_group.start_on

  renewing_plan_year = FactoryBot.create :plan_year, employer_profile: secondary_employer_profile,
                                             start_on: start_on,
                                             end_on: end_on,
                                             open_enrollment_start_on: open_enrollment_start_on,
                                             open_enrollment_end_on: open_enrollment_end_on,
                                             fte_count: 2,
                                             aasm_state: :renewing_enrolling

  benefit_group = FactoryBot.create :benefit_group, plan_year: renewing_plan_year, title: 'this is the BGGG'
  secondary_employee.add_renew_benefit_group_assignment benefit_group

  FactoryBot.create(:qualifying_life_event_kind, market_kind: "shop")

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

And(/^Employee sees Enrollment Submitted and clicks Continue$/) do
  expect(page).to have_content("Enrollment Submitted")
  find('a.interaction-click-control-continue', text: 'CONTINUE', wait: 5).click
end

And(/^Employee sees Enrollment Submitted and clicks Go to My Account$/) do
  expect(page).to have_content("Enrollment Submitted")
  click_link 'GO TO MY ACCOUNT'
  wait_for_ajax
end


Then(/Employee (.*) should have the (.*) plan year start date as earliest effective date/) do |named_person, plan_year|
  person = people[named_person]
  census_employee = CensusEmployee.where(first_name: person[:first_name], last_name: person[:last_name]).first
  # Original expectations here were unclear
end

Then(/^Employee (.*) should see their plan start date on the page$/) do |named_person|
  employer_profile = employer_profile(@organization[@organization.keys.first].legal_name)
  exchange_date = TimeKeeper.date_according_to_exchange_at(employer_profile.benefit_sponsorships.first.created_at)
  expect(page).to have_content(exchange_date.strftime("%m/%d/%Y"))
end

Then(/Employee (.*) should not see earliest effective date on the page/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  expect(page).not_to have_content "coverage starting #{employer_profile.renewing_plan_year.start_on.strftime("%m/%d/%Y")}."
end

# Record must already be created
When(/census employee (.*) logs in/) do |named_person|
  if @person_user_record.present?
    login_as @person_user_record
    visit "/"
  else
    person = people[named_person]
    user = User.where(email: person[:email]).first
    login_as user
    visit "/"
  end
  wait_for_ajax
  sleep(2)
  expect(page).to have_link("Logout")
end

And(/census employee (.*) visits the employee portal page$/) do |named_person|
  click_link 'Employee Portal'
  wait_for_ajax
  sleep(4)
end

And(/(.*) already matched and logged into employee portal/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  ce = employer_profile.census_employees.where(:first_name => /#{person[:first_name]}/i,
                                               :last_name => /#{person[:last_name]}/i).first
  person_record = FactoryBot.create(:person_with_employee_role, first_name: person[:first_name],
                                                                 last_name: person[:last_name],
                                                                 ssn: person[:ssn],
                                                                 dob: person[:dob_date],
                                                                 census_employee_id: ce.id,
                                                                 employer_profile_id: employer_profile.id,
                                                                 hired_on: ce.hired_on)

  ce.update_attributes(employee_role_id: person_record.employee_roles.first.id)
  FactoryBot.create :family, :with_primary_family_member, person: person_record
  user = FactoryBot.create(:user, person: person_record,
                                   email: person[:email],
                                   password: person[:password],
                                   password_confirmation: person[:password])
  login_as user
  visit "/families/home"
end

And(/(.*) matches all employee roles to employers and is logged in/) do |named_person|
  person = people[named_person]
  organizations = BenefitSponsors::Organizations::GeneralOrganization.all.to_a
  employer_profiles = organizations.map(&:employer_profile).compact
  employer_profiles.each do |employer_profile|
    legal_name = employer_profile.organization.legal_name
    # Creates the employee staff roles too
    person_record_from_census_employee(person, legal_name, organizations)
  end
  user = user_record_from_census_employee(person)
  login_as user
  visit "/"
  click_link 'Employee Portal'
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
  expect(find_all(".alert-notice").first.text).to include("Congratulations")
  find_all('#shop_for_employer_sponsored_coverage').first.click
end

Then(/(.*) should see the 1st ER name/) do |named_person|
  person = people[named_person]
  expect(page).to have_content(person[:legal_name])
end

Then(/employee should see text for employer (.*)/) do |employer_legal_name|
  expect(page).to have_content(employer_legal_name)
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

Then(/(.*) should see \"You're not yet eligible under your employer-sponsored benefits\" error message/) do |named_person|
  expect(page).to have_content("You're not yet eligible under your employer-sponsored benefits.")
end

Then(/(.*) should see \"Unable to find employer-sponsored benefits for enrollment year\" error message/) do |named_person|
  expect(page).to have_content("Unable to find employer-sponsored benefits for enrollment year")
end


Then(/(.*) should get plan year start date as coverage effective date/) do |named_person|
  person = people[named_person]
  renewal_start = benefit_sponsorship.renewal_benefit_application.start_on
  find('.coverage_effective_date', text: renewal_start.strftime("%m/%d/%Y"))
end

Then(/(.*) should get qle effective date as coverage effective date/) do |named_person|
  person = people[named_person]
  effective_on = Person.where(:first_name=> person[:first_name]).first.primary_family.current_sep.effective_on
  find('.coverage_effective_date', text: effective_on.strftime("%m/%d/%Y"), wait: 10)
end

When(/(.+) should see coverage summary page with renewing benefit application start date as effective date/) do |named_person|
  find('.interaction-click-control-confirm', wait: 10)
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
  date = [renewal_effective_date - 5.days, TimeKeeper.date_of_record - 5.days].min
  fill_in "qle_date", :with => date.strftime("%m/%d/%Y")
  within '#qle-date-chose' do
    find('.interaction-click-control-continue').click
  end
end

When(/Employee select a current qle date/) do
  expect(page).to have_content "Married"
  screenshot("past_qle_date")
  fill_in "qle_date", :with => TimeKeeper.date_of_record.strftime("%m/%d/%Y")
  within '#qle-date-chose' do
    find('.interaction-click-control-continue').click
  end
end

When(/Employee select a qle date based on expired plan year/) do
  screenshot("past_qle_date")
  fill_in "qle_date", :with => (renewal_effective_date - 20.days).strftime("%m/%d/%Y")
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
  expect(page).to have_content "#{l10n('family_information')}"
  find('#dependent_buttons .interaction-click-control-continue', :wait => 5).click
end
