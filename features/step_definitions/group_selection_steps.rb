Given (/a matched Employee exists with multiple employee roles/) do
  org1 = FactoryBot.create :organization, :with_active_plan_year
  org2 = FactoryBot.create :organization, :with_active_plan_year_and_without_dental
  benefit_group1 = org1.employer_profile.plan_years[0].benefit_groups[0]
  benefit_group2 = org2.employer_profile.plan_years[0].benefit_groups[0]
  bga1 = FactoryBot.build :benefit_group_assignment, benefit_group: benefit_group1
  bga2 = FactoryBot.build :benefit_group_assignment, benefit_group: benefit_group2
  FactoryBot.create(:user)
  @person = FactoryBot.create(:person, :with_family, first_name: "Employee", last_name: "E", user: user)
  employee_role1 = FactoryBot.create :employee_role, person: @person, employer_profile: org1.employer_profile
  employee_role2 = FactoryBot.create :employee_role, person: @person, employer_profile: org2.employer_profile
  ce1 =  FactoryBot.build(:census_employee,
          first_name: @person.first_name,
          last_name: @person.last_name,
          dob: @person.dob,
          ssn: @person.ssn,
          employee_role_id: employee_role1.id,
          employer_profile: org1.employer_profile
        )
  ce2 =  FactoryBot.build(:census_employee,
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
  FactoryBot.create(:employee_role, person: @person, employer_profile: @profile, benefit_sponsors_employer_profile_id: @profile.id)
  ce = FactoryBot.build(
    :benefit_sponsors_census_employee_with_active_assignment,
    first_name: @person.first_name,
    last_name: @person.last_name,
    dob: @person.dob,
    ssn: @person.ssn,
    employer_profile: @profile,
    employee_role_id: @person.employee_roles.first.id,
    benefit_sponsorship: @sponsorship
  )
  ce.save!
  @person.employee_roles.first.update_attributes(census_employee_id: ce.id)
  FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
end


And(/(.*) has a dependent in (.*) relationship with age (.*) than 26/) do |role, kind, var|
  dob = (var == "greater" ? TimeKeeper.date_of_record - 35.years : TimeKeeper.date_of_record - 5.years)
  family = Family.all.first
  dependent = if role == 'employee'
                FactoryBot.create :person, dob: dob
              elsif role == 'Resident'
                FactoryBot.create :person, :with_resident_role, :with_active_resident_role, dob: dob
              else
                FactoryBot.create :person, :with_consumer_role, :with_active_consumer_role, dob: dob
              end
  fm = FactoryBot.create :family_member, family: family, person: dependent
  final_person = @person || user.person
  final_person.ensure_relationship_with(dependent, kind)
  ch = family.active_household.immediate_family_coverage_household
  ch.coverage_household_members << CoverageHouseholdMember.new(family_member_id: fm.id)
  ch.save
  final_person.save
end

And(/(.*) also has a health enrollment with primary person covered/) do |role|
  family = Family.all.first
  # qle = FactoryBot.create(:qualifying_life_event_kind,market_kind: @employee_role.present? ? "employer_sponsored" : "individual")
  if ["consumer","Resident","user"].include? role
    qle = FactoryBot.create :qualifying_life_event_kind, market_kind: "individual"
    sep = FactoryBot.create :special_enrollment_period, qualifying_life_event_kind_id: qle.id, family: family
  else
    sep = FactoryBot.create :special_enrollment_period, family: family
  end
  document = FactoryBot.build(:document, identifier: '525252')
  product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile, sbc_document: document, :metal_level_kind => :silver)

  if role == 'consumer'
    FactoryBot.create(:hbx_profile, :no_open_enrollment_coverage_period)
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.date_of_record)}.update_attributes!(slcsp_id: product.id)
    consumer_role = family.primary_applicant.person.consumer_role

    tax_household = family.active_household.tax_households[0] || FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)
    FactoryBot.create(:tax_household_member, applicant_id: family.primary_applicant.id, tax_household: tax_household)
    FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household, csr_eligibility_kind: 'csr_73')
  end
  sep.update_attributes!(effective_on: TimeKeeper.date_of_record.end_of_month)
  kind =
    if @employee_role.present?
      'employer_sponsored'
    elsif role == "Resident"
      'coverall'
    else
      'individual'
    end
  enrollment =
    FactoryBot.create(
      :hbx_enrollment,
      product: product,
      household: family.active_household,
      family: family,
      kind: kind,
      effective_on: TimeKeeper.date_of_record,
      enrollment_kind: "special_enrollment",
      special_enrollment_period_id: sep.id,
      consumer_role_id: (consumer_role.id if consumer_role.present?),
      employee_role_id: (@employee_role.id if @employee_role.present?),
      benefit_group_id: (@benefit_group.id if @benefit_group.present?)
    )
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: family.primary_applicant.id,
    eligibility_date: TimeKeeper.date_of_record - 2.months,
    coverage_start_on: TimeKeeper.date_of_record - 2.months
  )
  enrollment.save!
end

And(/(.*) has a health enrollment with dependent covered/) do |role|
  family = Family.all.first
  enrollment = family.hbx_enrollments.first
  chm = family.active_household.immediate_family_coverage_household.coverage_household_members.last
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: chm,
    eligibility_date: TimeKeeper.date_of_record - 2.months,
    coverage_start_on: TimeKeeper.date_of_record - 2.months
  )
  enrollment.save!
end

And(/(.*) also has a dental enrollment with primary person covered/) do |role|
  family = Family.all.first
  if ["consumer","Resident","user"].include? role
    qle = FactoryBot.create :qualifying_life_event_kind, market_kind: "individual"
    sep = FactoryBot.create :special_enrollment_period, qualifying_life_event_kind_id: qle.id, family: family
  else
    sep = FactoryBot.create :special_enrollment_period, family: family
  end
  kind = if @employee_role.present?
           "employer_sponsored"
         else
           if role == "Resident"
             "coverall"
           else
             "individual"
           end
         end
  product = FactoryBot.create(:benefit_markets_products_dental_products_dental_product, :with_issuer_profile, dental_level: 'low', dental_plan_kind: 'ppo')
  enrollment = FactoryBot.create(:hbx_enrollment, product: product,
                                                  household: family.active_household,
                                                  family: family,
                                                  kind: kind,
                                                  effective_on: TimeKeeper.date_of_record,
                                                  enrollment_kind: "special_enrollment",
                                                  special_enrollment_period_id: sep.id,
                                                  employee_role_id: (@employee_role.id if @employee_role.present?),
                                                  benefit_group_id: (@benefit_group.id if @benefit_group.present?))
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: family.primary_applicant.id,
                                                               eligibility_date: TimeKeeper.date_of_record - 2.months,
                                                               coverage_start_on: TimeKeeper.date_of_record - 2.months)
  enrollment.save!
end

And(/employee also has a (.*) enrollment with primary covered under (.*) employer/) do |coverage_kind, var|
  sep = FactoryBot.create :special_enrollment_period, family: @person.primary_family
  family = Family.all.first
  product = if coverage_kind == 'dental'
              FactoryBot.create(:benefit_markets_products_dental_products_dental_product, :with_issuer_profile, dental_level: 'low', dental_plan_kind: 'ppo')
            else
              FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile)
            end
  benefit_group = if var == "first"
                    @person.active_employee_roles[0].employer_profile.plan_years[0].benefit_groups[0]
                  else
                    @person.active_employee_roles[1].employer_profile.plan_years[0].benefit_groups[0]
                  end
  benefit_package =  @person.active_employee_roles.first.employer_profile.benefit_sponsorships.first.benefit_applications.first.benefit_packages.first
  enrollment = FactoryBot.create(:hbx_enrollment, product: product,
                                  household: @person.primary_family.active_household,
                                  kind: "employer_sponsored",
                                  effective_on: TimeKeeper.date_of_record,
                                  coverage_kind: coverage_kind,
                                  family: family,
                                  enrollment_kind: "special_enrollment",
                                  special_enrollment_period_id: sep.id,
                                  employee_role_id: (var == "first" ? @person.active_employee_roles[0].id : @person.active_employee_roles[1].id),
                                  benefit_group_id: benefit_group.id,
                                  rating_area_id: benefit_package.rating_area.id,
                                  sponsored_benefit_package_id: benefit_package.id,
                                  sponsored_benefit: benefit_package.sponsored_benefits[1]
                                )
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: @person.primary_family.primary_applicant.id,
    eligibility_date: TimeKeeper.date_of_record - 2.months,
    coverage_start_on: TimeKeeper.date_of_record - 2.months
  )
  enrollment.save!
end

Given (/a matched Employee exists with active and renwal plan years/) do
  FactoryBot.create(:user)
  person = FactoryBot.create(:person, :with_employee_role, :with_family, first_name: "Employee", last_name: "E", user: user)
  org = FactoryBot.create :organization, :with_active_and_renewal_plan_years
  @active_benefit_group = org.employer_profile.active_plan_year.benefit_groups[0]
  active_bga = FactoryBot.build :benefit_group_assignment, benefit_group: @active_benefit_group
  benefit_package = FactoryBot.build :benefit_package

  @renewal_benefit_group = org.employer_profile.show_plan_year.benefit_groups[0]
  renewal_bga = FactoryBot.build :benefit_group_assignment, benefit_group: @renewal_benefit_group, benefit_package_id: benefit_package.id

  @employee_role = person.employee_roles[0]
  ce =  FactoryBot.build(:census_employee,
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
    expect(first("input[type='checkbox']:disabled", wait: 5)).to be_disabled
    expect(first("input[type='checkbox']:disabled")).not_to be_checked
  else
    expect(find("#family_member_ids_0", wait: 5)).not_to be_disabled
    expect(find("#family_member_ids_0")).to be_checked
  end
end

And(/Employer not offers dental benefits for spouse in renewal plan year/) do
  benefits = @renewal_benefit_group.dental_relationship_benefits
  until benefits.blank?
    benefits.each { |rb| rb.delete }
  end
  rbs = [FactoryBot.build_stubbed(:dental_relationship_benefit, benefit_group: @renewal_benefit_group, relationship: :employee, premium_pct: 49, employer_max_amt: 1000.00),
         FactoryBot.build_stubbed(:dental_relationship_benefit, benefit_group: @renewal_benefit_group, relationship: :spouse, premium_pct: 40, employer_max_amt:  200.00, offered: false)]
  @renewal_benefit_group.save
end

And(/(.*) should also see the reason for ineligibility/) do |named_person|
  person_hash = people[named_person]
  person = person_hash ? Person.where(:first_name => /#{person_hash[:first_name]}/i, :last_name => /#{person_hash[:last_name]}/i).first : ''
  person = person.empty? ? @person : ''
  role = named_person

  if role == 'employee' && person.active_employee_roles.present?
    expect(page).to have_content "Employer sponsored coverage is not available"
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
  expect(page).to have_content "Coverage For:   #{primary.full_name} + 1 Dependent"
end

And(/(.*) selects high for metal level plan and metal level box appears selected/) do |_role|
  Capybara.ignore_hidden_elements = false
  page.all('label').detect { |input| input[:for] == 'plan-metal-level-high' }.click
  sleep 5
  expect(find('#plan-metal-level-high')[:disabled]).to_not eq('true')
  Capybara.ignore_hidden_elements = true
end

Then(/(.*) should only see the dependent name/) do |role|
  dependent = Person.all.select { |person| person.primary_family.blank? }.first
  expect(page).to have_content "Coverage For:   #{dependent.full_name}"
end

Then(/(.*) should see primary person/) do |role|
  primary = Person.all.select { |person| person.primary_family.present? }.first
  expect(page).to have_content "Coverage For:   #{primary.first_name}"
end

Then(/(.*) should see the enrollment with make changes button/) do |role|
  if role == "employee"
    expect(page).to have_content "#{(@current_effective_date || TimeKeeper.date_of_record).year} HEALTH COVERAGE"
  else
    expect(page).to have_content "#{TimeKeeper.date_of_record.year} HEALTH COVERAGE"
  end
  expect(page).to have_link "Make Changes"
end

Then(/(.*) should see the dental enrollment with make changes button/) do |role|
  if role == "employee"
    expect(page).to have_content "#{(@current_effective_date || TimeKeeper.date_of_record).year} DENTAL COVERAGE"
  else
    expect(page).to have_content "#{TimeKeeper.date_of_record.year} DENTAL COVERAGE"
  end
  expect(page).to have_link "Make Changes"
end

When(/(.*) clicked on make changes button/) do |_role|
  click_link('Make Changes',  wait: 10)
end

Then(/(.*) should see keep existing plan and select plan to terminate button/) do |_role|
  expect(page).to have_button('Keep existing plan')
  expect(page).to have_link "Select Plan to Terminate"
end

When(/(.*) clicked on keep existing plan button/) do |_role|
  click_button "Keep existing plan"
end

Then(/consumer should land on confirm page/) do
  expect(page).to have_content "Confirm Your Plan Selection"
  expect(page).to have_content "Premium"
end

Then(/consumer should enrollment submitted confirmation page/) do
  expect(page).to have_content "Enrollment Submitted"
  expect(page).to have_content "Premium"
end

Then(/cosumer should see the home page/) do
  expect(page).to have_content "My #{Settings.site.short_name}"
end

When(/(.*) clicked continue on household info page/) do |role|
  find_all("#btn_household_continue")[0].click
end

Then(/(.*) should see all the family members names/) do |role|
  people = Person.all
  people.each do |person|
    expect(page).to have_content "#{person.last_name}"
    expect(page).to have_content "#{person.first_name}"

  end
end

When(/(.*) (.*) the primary person/) do |role, checked|
  if checked == "checks"
    find("#family_member_ids_0").set(true)
  else
    find("#family_member_ids_0").set(false)
  end
end

And(/(.*) selects (.*) for coverage kind/) do |_role, coverage_kind|
  find("##{coverage_kind}-radio-button").click
end

And(/(.*) clicked on shop for new plan/) do |role|
  find(".interaction-click-control-shop-for-new-plan").click
end

And(/user did not apply coverage for child as ivl/) do
  family = Family.all.first
  family.family_members.detect { |fm| fm.primary_relationship == "child"}.person.consumer_role.update_attributes(is_applying_coverage: false)
end

And(/employee has a valid "(.*)" qle/) do |qle|
  qle = FactoryBot.create :qualifying_life_event_kind, title: qle
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

And(/ER not offers benefits for child/) do
  benefit_group = @person.active_employee_roles[0].employer_profile.plan_years[0].benefit_groups[0]
  benefit_group.health_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: "Child Under 26").first.update_attributes!(is_offered: false)
  benefit_group.dental_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: "Child Under 26").first.update_attributes!(is_offered: false)
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
  find(".interaction-click-control-shop-for-plans", :wait => 10).click
end

When(/employee switched for (.*) benefits/) do |market_kind|
  if market_kind == "individual"
    find(:label, 'Individual Benefits').click
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

And(/(.*) clicked on continue for plan shopping$/) do |_user|
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

When(/Resident has QLE and goes to home page/) do
  # we have only shop & ivl as market kinds for qle
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryBot.create(:hbx_profile, :no_open_enrollment_coverage_period)
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  visit "/families/home"
end

And(/Resident clicked on "Married" qle/) do
  click_link "Married"
end

# Replaced with Make Changes, commented out in case it's needed later
# Then(/consumer (.*) see the edit plan button/) do |visibility|
#   if visibility.eql?("should")
#     expect(page).to have_selector("a", text: "Edit Plan",  count: 1)
#   else
#     expect(page).to_not have_selector("a", text: "Edit Plan",  count: 1)
#   end
# end

Then(/^.* (.*) see make changes button in (.*) market/) do |visibility, market|
  # There are two different buttons, each with links. one for IVl and one for SHOP
  case market
  when 'individual'
    css_class = '.ivl-make-changes'
  when 'shop'
    css_class = '.ee-make-changes'
  end
  case visibility
  when 'should'
    expect(page).to have_css(css_class)
  else
    expect(page).to_not have_css(css_class)
  end
end

# Replaced with Make Changes, commented out in case it's needed later
# When(/(.*) clicks on the edit plan button/) do |_role|
#   click_link 'Edit Plan'
# end

When(/^\w+ should be able to see Actions dropdown$/) do
  page.all("#dropdownMenuButton").count > 0
end

Then(/^\w+ clicks on the Actions button$/) do
  page.all("#dropdownMenuButton").first.click
end

And(/^\w+ should see able to see make changes to my coverage button$/) do
  page.all('a', text: 'Make changes to my coverage').first
end

When(/^\w+ clicks on the make changes to my coverage button/) do
  enable_change_tax_credit_button
  page.all('a', text: 'Make changes to my coverage').first.click
  wait_for_ajax
end

When(/(.*) clicks on the make changes button/) do |_role|
  enable_change_tax_credit_button
  page.all('a', text: 'Make changes to my coverage').first.click
  wait_for_ajax
end

When(/(.*) clicks on the dental make changes button/) do |_role|
  page.all('a', text: 'Make Changes').first.click
end

Then(/(.*) should see the make changes page/) do |_role|
  wait_for_ajax
  expect(page).to have_text('Tax credit amount')
end

When(/(.*) clicks on the Cancel Plan button/) do |_role|
  find('.interaction-click-control-cancel-plan').click
end

Then(/(.*) should see the calender/) do |_role|
  expect(page).to have_selector :css, '.date-picker'
end

Then(/the submit button should be disabled/) do
  expect(page).to have_button('Are you sure?', disabled: true)
end

When(/(.*) selects a date/) do |_role|
  fill_in 'term-date', :with => (TimeKeeper.date_of_record + 10).to_s
end

Then(/the submit button should be enabled/) do
  expect(page).to have_button('Are you sure?', disabled: false)
end

When(/(.*) clicks the submit button/) do |_role|
  click_button('Are you sure?')
end

Then(/the enrollment should be terminated/) do
  expect(Family.all.first.all_enrollments.first.aasm_state).to eq('coverage_terminated')
  expect(page).to have_content('Coverage End: ' + (TimeKeeper.date_of_record + 10).to_s)
end

# Given(/(.*) has a (.*) secondary role/) do |_primary_role, secondary_role|
#  Family.all.first.all_enrollments.first.aasm_state == 'coverage_terminated'
# end

Then(/the enrollment should be pending termination/) do
  expect(Family.all.first.all_enrollments.first.aasm_state).to eq('coverage_termination_pending')
  expect(page).to have_content('Coverage End: ' + (TimeKeeper.date_of_record + 10).to_s)
end

Given(/(.*) has a (.*) secondary role/) do |_primary_role, secondary_role|
  family = Family.all.first
  # Assumes primary role is consumer.
  if secondary_role.eql?('resident')
    FactoryBot.create(:resident_role_object, person: family.primary_person)
  elsif secondary_role.eql?('employee')
    FactoryBot.create(:employee_role, person: family.primary_person)
  end
end

When(/consumer's health enrollment has an effective date in the future/) do
  Family.all.first.all_enrollments.first.update_attributes(effective_on: TimeKeeper.date_of_record + 20)
  @family.all_enrollments.first.aasm_state == 'coverage_terminated'
end


# Given(/(.*) has a (.*) role/) do |_primary_role, secondary_role|
#  family = Family.all.first
#  # Assumes primary role is consumer.
#  if secondary_role.eql?('resident')
#    FactoryBot.create(:resident_role_object, person: family.primary_person)
#  elsif secondary_role.eql?('employee')
#    FactoryBot.create(:employee_role, person: family.primary_person)
#  end
# end

When(/consumer's dental enrollment has an effective date in the future/) do
  Family.all.last.all_enrollments.first.update_attributes(effective_on: TimeKeeper.date_of_record + 20)
end

Then(/(.*) should not see the calender/) do |_role|
  expect(page).not_to have_selector :css, '.date-picker'
end

When(/(.*) selects (.*) to are you sure/) do |_role, option|
  if option.eql?('yes')
    choose('agreement_action-confirm-yes')
  else
    choose('agreement_action-confirm-no')
  end
end

Then(/the enrollment should be canceled/) do
  expect(Family.all.first.all_enrollments.first.aasm_state).to eq('coverage_canceled')
  #Enrollment tile should not show
  expect(page).not_to have_content("View Details")
end

Then(/the dental enrollment should be canceled/) do
  expect(Family.all.first.all_enrollments.last.aasm_state).to eq('coverage_canceled')
  #Enrollment tile should not show
  expect(page).not_to have_content("View Details")
end

When(/(.*) clicks on the Shop for Plans button/) do |_role|
  find('.interaction-click-control-shop-for-plans').click
end

And(/the enrollment is in (.*) state/) do |state|
  Family.all.first.all_enrollments.first.update_attributes(aasm_state: state)
  # Refresh page to ensure UI change
  visit current_path
end

And(/the family has an active tax household/) do
  @family = Family.all.first
  household = @family.active_household
  household.tax_households[0] || FactoryBot.create(:tax_household, household: @family.active_household)
end

And(/the tax household has at least one member that is APTC eligible/) do
  tax_household = @family.active_household.latest_active_tax_household || FactoryBot.create(:tax_household, household: @family.active_household)
  tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: @family.enrollments.first.hbx_enrollment_members.first.applicant_id)
  FactoryBot.create(:eligibility_determination, max_aptc: 500, tax_household: tax_household)
end

And(/the tax household has no members that are APTC eligible/) do
  tax_household = @family.active_household.latest_active_tax_household || FactoryBot.create(:tax_household, household: @family.active_household)
  tax_household.tax_household_members.each do |thhm|
    thhm.update_attributes(is_ia_eligible: false, applicant_id: @family.enrollments.first.hbx_enrollment_members.first.applicant_id)
  end
end

And(/the metal level is (.*)/) do |metal_level|
  @family.enrollments.first.product.update_attributes(metal_level_kind: metal_level.to_sym)
end

Then(/the Change Tax Credit button should be available/) do
  sleep(2)
  expect(page).to have_content("Change Tax Credit")
end

Then(/the Change Tax Credit button should NOT be available/) do
  expect(page).to_not have_content("Tax Credit amount")
end

When(/the user clicks on the Change Tax Credit button/) do
  find("#aptc-button").click
end

When(/the user submits the Change Tax Credit form/) do
  find("#update-aptc-button").click
end

And(/the user sees the Change Tax Credit Form/) do
  expect(page).to have_content("Are you sure you want to update your tax credit?")
end

When(/the user changes Tax credit applied to 50%/) do
  fill_in("aptc_applied_total", with: "50.0")
  page.execute_script('$(document.elementFromPoint(50, 350)).click();')
end

And(/the user confirms "Yes" to change the tax credit/) do
  find("#agreement_action-confirm-yes-change-tax-credit").click
end

Then(/the user should see a message that their Tax Credits were updated/) do
  wait_for_ajax
  expect(page).to have_content("Tax credit updated successfully.")
end

Then(/the user should see that applied tax credit has been set accordingly/) do
  expect(page).to have_content("25")
end

Given(/the enrollment has HIOS ID ending in (.*)/) do |id_number|
  hios_id = @family.enrollments.first.product.hios_id
  changed_id = hios_id.gsub(hios_id[-2..-1], id_number)
  @family.enrollments.first.product.update_attributes(hios_id: changed_id)
end

Given(/the enrollment is a Health plan/) do
  @family.enrollments.first.update_attributes!(coverage_kind: "health")
end

Given(/the enrollment is a Dental plan/) do
  @family.enrollments.first.update_attributes!(coverage_kind: "dental")
end

Given(/the coverall enrollment flag is TRUE/) do
  @family.enrollments.first.update_attributes!(kind: "coverall")
end
