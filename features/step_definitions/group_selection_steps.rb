
Given (/a matched Employee exists with multiple employee roles/) do
  org1 = FactoryGirl.create :organization, :with_active_plan_year
  org2 = FactoryGirl.create :organization, :with_active_plan_year_and_without_dental
  benefit_group1 = org1.employer_profile.plan_years[0].benefit_groups[0]
  benefit_group2 = org2.employer_profile.plan_years[0].benefit_groups[0]
  bga1 = FactoryGirl.build :benefit_group_assignment, benefit_group: benefit_group1
  bga2 = FactoryGirl.build :benefit_group_assignment, benefit_group: benefit_group2
  FactoryGirl.create(:user)
  @person = FactoryGirl.create(:person, :with_family, first_name: "Employee", last_name: "E", user: user)
  employee_role1 = FactoryGirl.create :employee_role, person: @person, employer_profile: org1.employer_profile
  employee_role2 = FactoryGirl.create :employee_role, person: @person, employer_profile: org2.employer_profile
  ce1 =  FactoryGirl.build(:census_employee,
          first_name: @person.first_name, 
          last_name: @person.last_name, 
          dob: @person.dob, 
          ssn: @person.ssn, 
          employee_role_id: employee_role1.id,
          employer_profile: org1.employer_profile
        )
  ce2 =  FactoryGirl.build(:census_employee,
          first_name: @person.first_name, 
          last_name: @person.last_name, 
          dob: @person.dob, 
          ssn: @person.ssn, 
          employee_role_id: employee_role2.id,
          employer_profile: org2.employer_profile
        )

  ce1.benefit_group_assignments << bga1
  ce1.link_employee_role!
  ce1.save!

  ce2.benefit_group_assignments << bga2
  ce2.link_employee_role!
  ce2.save!

  employee_role1.update_attributes(census_employee_id: ce1.id, employer_profile_id: org1.employer_profile.id)
  employee_role2.update_attributes(census_employee_id: ce2.id, employer_profile_id: org2.employer_profile.id)
end

Given (/a matched Employee exists with consumer role/) do
  org = FactoryGirl.create :organization, :with_active_plan_year
  benefit_group = org.employer_profile.plan_years[0].benefit_groups[0]
  bga = FactoryGirl.build :benefit_group_assignment, benefit_group: benefit_group
  FactoryGirl.create(:user)
  @person = FactoryGirl.create(:person, :with_family, :with_consumer_role, :with_active_consumer_role, first_name: "Employee", last_name: "E", user: user)
  employee_role = FactoryGirl.create :employee_role, person: @person, employer_profile: org.employer_profile
  ce =  FactoryGirl.build(:census_employee,
          first_name: @person.first_name, 
          last_name: @person.last_name, 
          dob: @person.dob, 
          ssn: @person.ssn, 
          employee_role_id: employee_role.id,
          employer_profile: org.employer_profile
        )

  ce.benefit_group_assignments << bga
  ce.link_employee_role!
  ce.save!

  employee_role.update_attributes!(census_employee_id: ce.id, employer_profile_id: org.employer_profile.id)
  ce.employee_role.reload
  FactoryGirl.create(:hbx_profile)
end


And(/(.*) has a dependent in (.*) relationship with age (.*) than 26/) do |role, kind, var|
  dob = (var == "greater" ? TimeKeeper.date_of_record - 35.years : TimeKeeper.date_of_record - 5.years)
  @family = Family.all.first
  if role == "employee"
    dependent = FactoryGirl.create :person, dob: dob
  elsif role == "Resident"
    dependent = FactoryGirl.create :person, :with_resident_role, dob: dob
  else
    dependent = FactoryGirl.create :person, :with_consumer_role, dob: dob
  end
  fm = FactoryGirl.create :family_member, family: @family, person: dependent
  user.person.person_relationships << PersonRelationship.new(kind: kind, relative_id: dependent.id)
  ch = @family.active_household.immediate_family_coverage_household
  ch.coverage_household_members << CoverageHouseholdMember.new(family_member_id: fm.id)
  ch.save
  user.person.save
end

And(/(.*) also has a health enrollment with primary person covered/) do |role|
  sep = FactoryGirl.create :special_enrollment_period, family: @family
  enrollment = FactoryGirl.create(:hbx_enrollment,
                                  household: @family.active_household,
                                  kind: (@employee_role.present? ? "employer_sponsored" : (role == "Resident" ? "coverall" : "individual")),
                                  effective_on: TimeKeeper.date_of_record,
                                  enrollment_kind: "special_enrollment",
                                  special_enrollment_period_id: sep.id,
                                  employee_role_id: (@employee_role.id if @employee_role.present?),
                                  benefit_group_id: (@benefit_group.id if @benefit_group.present?)
                                )
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: @family.primary_applicant.id,
    eligibility_date: TimeKeeper.date_of_record - 2.months,
    coverage_start_on: TimeKeeper.date_of_record - 2.months
  )
  enrollment.save!
end

And(/employee also has a (.*) enrollment with primary covered under (.*) employer/) do |coverage_kind, var|
  sep = FactoryGirl.create :special_enrollment_period, family: @person.primary_family
  benefit_group = if var == "first"
                    @person.active_employee_roles[0].employer_profile.plan_years[0].benefit_groups[0]
                  else
                    @person.active_employee_roles[1].employer_profile.plan_years[0].benefit_groups[0]
                  end
  enrollment = FactoryGirl.create(:hbx_enrollment,
                                  household: @person.primary_family.active_household,
                                  kind: "employer_sponsored",
                                  effective_on: TimeKeeper.date_of_record,
                                  coverage_kind: coverage_kind,
                                  enrollment_kind: "special_enrollment",
                                  special_enrollment_period_id: sep.id,
                                  employee_role_id: (var == "first" ? @person.active_employee_roles[0].id : @person.active_employee_roles[1].id),
                                  benefit_group_id: benefit_group.id
                                )
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: @person.primary_family.primary_applicant.id,
    eligibility_date: TimeKeeper.date_of_record - 2.months,
    coverage_start_on: TimeKeeper.date_of_record - 2.months
  )
  enrollment.save!
end

Given (/a matched Employee exists with active and renwal plan years/) do
  FactoryGirl.create(:user)
  person = FactoryGirl.create(:person, :with_employee_role, :with_family, first_name: "Employee", last_name: "E", user: user)
  org = FactoryGirl.create :organization, :with_active_and_renewal_plan_years
  @active_benefit_group = org.employer_profile.active_plan_year.benefit_groups[0]
  active_bga = FactoryGirl.build :benefit_group_assignment, benefit_group: @active_benefit_group

  @renewal_benefit_group = org.employer_profile.show_plan_year.benefit_groups[0]
  renewal_bga = FactoryGirl.build :benefit_group_assignment, benefit_group: @renewal_benefit_group

  @employee_role = person.employee_roles[0]
  ce =  FactoryGirl.build(:census_employee,
          first_name: person.first_name, 
          last_name: person.last_name, 
          dob: person.dob, 
          ssn: person.ssn, 
          employee_role_id: @employee_role.id,
          employer_profile: org.employer_profile
        )
  [renewal_bga, active_bga].each do |bga|
    ce.benefit_group_assignments << bga
  end

  ce.link_employee_role!
  ce.save!

  @employee_role.update_attributes(census_employee_id: ce.id, employer_profile_id: org.employer_profile.id)
end

And(/(.*) should see the (.*) family member (.*) and (.*)/) do |employee, type, disabled, checked|
  wait_for_ajax
  if type == "ineligible"
    expect(find("#family_member_ids_1")).to be_disabled
    expect(find("#family_member_ids_1")).not_to be_checked
  else
    expect(find("#family_member_ids_0")).not_to be_disabled
    expect(find("#family_member_ids_0")).to be_checked
  end
end

And(/Employer not offers dental benefits for spouse in renewal plan year/) do
  benefits = @renewal_benefit_group.dental_relationship_benefits
  until benefits.blank?
    benefits.each { |rb| rb.delete }
  end
  rbs = [FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: @renewal_benefit_group, relationship: :employee, premium_pct: 49, employer_max_amt: 1000.00),
         FactoryGirl.build_stubbed(:dental_relationship_benefit, benefit_group: @renewal_benefit_group, relationship: :spouse, premium_pct: 40, employer_max_amt:  200.00, offered: false)]
  @renewal_benefit_group.save
end

And(/(.*) should also see the reason for ineligibility/) do |role|
  if role == "employee"
    expect(page).to have_content "This dependent is ineligible for employer-sponsored"
  else
    expect(page).to have_content "eligibility failed on family_relationships"
  end
end

And(/(.*) should see the dental radio button/) do |role|
  expect(page).to have_content "Dental"
end

And(/(.*) switched to dental benefits/) do |role|
  # choose("coverage_kind_dental")
  wait_for_ajax
  find(:xpath, '//*[@id="dental-radio-button"]/label').click
end

Then(/the primary person checkbox should be in unchecked status/) do
  expect(find("#family_member_ids_0")).not_to be_checked
end

Then(/(.*) should see both dependent and primary/) do |role|
  primary = Person.all.select { |person| person.primary_family.present? }.first
  expect(page).to have_content "COVERAGE FOR: #{primary.full_name} + 1 Dependent"
end

Then(/(.*) should only see the dependent name/) do |role|
  dependent = Person.all.select { |person| person.primary_family.blank? }.first
  expect(page).to have_content "COVERAGE FOR: #{dependent.full_name}"
end

Then(/(.*) should see primary person/) do |role|
  primary = Person.all.select { |person| person.primary_family.present? }.first
  expect(page).to have_content "COVERAGE FOR: #{primary.full_name}"
end

Then(/(.*) should see the enrollment with make changes button/) do |role|
  expect(page).to have_content "#{TimeKeeper.date_of_record.year} HEALTH COVERAGE"
  expect(page).to have_link "Make Changes"
end

Then(/(.*) should see the dental enrollment with make changes button/) do |role|
  expect(page).to have_content "#{TimeKeeper.date_of_record.year} DENTAL COVERAGE"
  expect(page).to have_link "Make Changes"
end

When(/(.*) clicked on make changes button/) do |role|
  click_link "Make Changes"
end

When(/(.*) clicked continue on household info page/) do |role|
  find_all("#btn_household_continue")[1].click
end

Then(/(.*) should see all the family members names/) do |role|
  people = Person.all
  people.each do |person|
    expect(page).to have_content "#{person.full_name}"
  end
end

When(/(.*) (.*) the primary person/) do |role, checked|
  if checked == "checks"
    find("#family_member_ids_0").set(true)
  else
    find("#family_member_ids_0").set(false)
  end
end

And(/(.*) clicked on shop for new plan/) do |role|
  find(".interaction-click-control-shop-for-new-plan").click
end

And(/user did not apply coverage for child as ivl/) do
  @family.family_members.detect { |fm| fm.primary_relationship == "child"}.person.consumer_role.update_attributes(is_applying_coverage: false)
end

And(/employee has a valid "(.*)" qle/) do |qle|
  qle = FactoryGirl.create :qualifying_life_event_kind, title: qle
end

And(/employee cannot uncheck primary person/) do
  expect(find("tr.is_primary td input")["onclick"]).to eq "return false;"
end

When(/employee (.*) the dependent/) do |checked|
  if checked == "checks"
    find("#family_member_ids_0").set(true)
  else
    find("#family_member_ids_1").set(false)
  end
end

And(/second ER not offers health benefits to spouse/) do
  benefit_group = @person.active_employee_roles[1].employer_profile.plan_years[0].benefit_groups[0]
  benefit_group.relationship_benefits.where(relationship: "spouse").first.update_attributes(offered: false)
  benefit_group.save
end

And(/first ER not offers dental benefits to spouse/) do
  benefit_group = @person.active_employee_roles[0].employer_profile.plan_years[0].benefit_groups[0]
  benefit_group.dental_relationship_benefits.where(relationship: "spouse").first.update_attributes(offered: false) rescue ""
  benefit_group.save
end

And(/employee should not see the reason for ineligibility/) do
  expect(page).not_to have_content "This dependent is ineligible for employer-sponsored"
end

When(/employee switched to (.*) employer/) do |employer|
  if employer == "first"
    find(:xpath, '//*[@id="employer-selection"]/div/div[1]/label').click
  else
    find(:xpath, '//*[@id="employer-selection"]/div/div[2]/label').click
  end
end

When(/employee clicked on shop for plans/) do
  find(".interaction-click-control-shop-for-plans").trigger('click')
  wait_for_ajax
end

When(/employee switched for (.*) benefits/) do |market_kind|
  if market_kind == "individual"
    find(:xpath, '//*[@id="market_kinds"]/div/div[2]/label').click
  else
    find(:xpath, '//*[@id="market_kinds"]/div/div[1]/label').click
  end
end

Then(/user should (.*) the ivl error message/) do |var|
  if var == "see"
    expect(page).to have_content "Did not apply for coverage"
  else
    expect(page).not_to have_content "Did not apply for coverage"
  end
end

And(/(.*) should not see the dental radio button/) do |role|
  expect(page).not_to have_content "Dental"
end

And(/employee clicked on continue for plan shopping/) do
  find(".interaction-click-control-continue").click
end

When(/employee clicked on make changes of health enrollment from first employer/) do
  find(:xpath, '//*[@id="account-detail"]/div[2]/div[1]/div[3]/div[3]/div/div[3]/div/span/a')
end

When(/employee clicked on back to my account/) do
  find(".interaction-click-control-back-to-my-account").click
end

And(/employee coverage effective on date is under active plan year/) do
  @employee_role.person.primary_family.current_sep.update_attributes(effective_on: TimeKeeper.date_of_record.beginning_of_day)
end

Given(/^a Resident exists$/) do
  user :with_resident_role
end

Given(/^the Resident is logged in$/) do
  login_as user
end

When(/Resident visits home page with qle/) do
  # we have only shop & ivl as market kinds for qle
  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryGirl.create(:hbx_profile, :no_open_enrollment_coverage_period)
  visit "/families/home"
end

And(/Resident clicked on "Married" qle/) do
  click_link "Married"
end

