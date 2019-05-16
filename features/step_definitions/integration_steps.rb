# load Rails.root + "db/seeds.rb"
When(/I use unique values/) do
  require 'test/unique_value_stash.rb'
  include UniqueValueStash
  @u = UniqueValueStash::UniqueValues.new unless defined?(@u)
end

def people
  return @a if defined?(@a)
  @a = {
    "Soren White" => {
      first_name: "Soren",
      last_name: "White",
      dob: "08/13/1979",
      dob_date: "13/08/1979".to_date,
      ssn: "670991234",
      home_phone: "2025551234",
      email: 'soren@dc.gov',
      password: 'aA1!aA1!aA1!',
      legal_name: "Acme Inc.",
      dba: "Acme Inc.",
      fein: @organization.present? ? @organization.values.first.employer_profile.fein : "764141112",
      sic_code: "0111",
      mlegal_name: "Cogswell Cogs, Inc",
      mdba: "Cogswell Cogs, Inc",
      mfein: "211141467"
    },
    "Patrick Doe" => {
      first_name: "Patrick",
      last_name: "Doe",
      dob: "01/01/1980",
      dob_date: "01/01/1980".to_date,
      ssn: "786120965",
      home_phone: "2025551234",
      email: 'patrick.doe@dc.gov',
      password: 'aA1!aA1!aA1!',
      fein: registering_employer.fein # 570834919
    },
    "Broker Assisted" => {
      first_name: 'Broker',
      last_name: 'Assisted',
      dob: "05/02/1976",
      ssn: "761234567",
      email: 'broker.assisted@dc.gov',
      password: 'aA1!aA1!aA1!'
    },
    "Fred" => {
      first_name: 'Fred',
      last_name: 'Thirteen',
      dob: defined?(@u) ? @u.adult_dob : "08/13/1979",
      ssn: defined?(@u) ? @u.ssn : "761234567",
      email: defined?(@u) ? @u.email : 'fred@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "Megan" => {
      first_name: 'Megan',
      last_name: 'Smith',
      dob: defined?(@u) ? @u.adult_dob : "08/13/1979",
      ssn: defined?(@u) ? @u.ssn : "761234567",
      email: defined?(@u) ? @u.email : 'megan@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "Hbx Admin" => {
      email: 'admin@dc.gov',
      password: 'aA1!aA1!aA1!'
    },
    "Primary Broker" => {
      email: 'ricky.martin@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "CareFirst Broker" => {
      first_name: 'Broker',
      last_name: 'martin',
      dob: "05/07/1977",
      ssn: "761111111",
      email: 'broker.martin@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "John Wood" => {
      first_name: "John",
      last_name: "Wood",
      dob: "03/13/1977",
      legal_name: "Acmega LLC",
      dba: "Acmega LLC",
      fein: "890112233",
      sic_code: "0111",
      email: 'johb.wood@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "John Doe" => {
      first_name: "John",
      last_name: "Doe#{rand(1000)}",
      dob: defined?(@u) ? @u.adult_dob : "08/13/1979",
      legal_name: "Turner Agency, Inc",
      dba: "Turner Agency, Inc",
      fein: defined?(@u) ? @u.fein : '123123123',
      ssn: defined?(@u) ? @u.ssn : "761234567",
      email: defined?(@u) ? @u.email : 'tronics@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "Jack Cobra" => {
      first_name: "Jack",
      last_name: "Cobra",
      dob: "08/10/1960",
      ssn: "196008107",
      email: "jack@cobra.com",
      password: 'aA1!aA1!aA1!'
    },
    "Jack Employee" => {
      first_name: "Jack",
      last_name: "Employee",
      dob: "08/10/1960",
      ssn: "196008111",
      email: "jack@employee.com",
      password: 'aA1!aA1!aA1!'
    },
    "Tim Wood" => {
      first_name: "Tim",
      last_name: "Wood",
      dob: "08/13/1979",
      legal_name: "Legal LLC",
      dba: "Legal LLC",
      fein: "890000223",
      sic_code: "0111",
      email: 'tim.wood@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "Tronics" => {
      first_name: "Tronics",
      last_name: "Rocks#{rand(1000)}",
      dob: defined?(@u) ?  @u.adult_dob : "08/13/1979",
      legal_name: "Tronics",
      dba: "Tronics",
      fein: defined?(@u) ? @u.fein : '123123123',
      email: defined?(@u) ? @u.email : 'tronics@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "CSR" => {
      email: "sherry.buckner@dc.gov",
      password: 'aA1!aA1!aA1!'
    },
    "Hbx AdminEnrollments" => {
      first_name: "Hbx Admin",
      last_name: "Enrollments#{rand(1000)}",
      dob: defined?(@u) ?  @u.adult_dob : "08/13/1979",
      legal_name: "Tronics",
      dba: "Tronics",
      fein: defined?(@u) ? @u.fein : '123123123',
      email: defined?(@u) ? @u.email : 'hxadmin_enroll@example.com',
      password: 'aA1!aA1!aA1!'
    }
  }
end

def scroll_into_view(element)
  @browser.execute_script(
    'arguments[0].scrollIntoView(false);',
    element
  )
  element
end

def scroll_then_click(element)
  scroll_into_view(element).click
  element
end

def click_when_present(element)
  element.wait_until_present
  scroll_then_click(element)
end

def wait_and_confirm_text(text)
  @browser.element(text: text).wait_until_present
  expect(@browser.element(text:text).visible?).to be_truthy
end

def fill_user_registration_form(credentials)
  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  @browser.text_field(name: "user[login]").set(credentials[:email])
  @browser.text_field(name: "user[password]").set(credentials[:password])
  @browser.text_field(name: "user[password_confirmation]").set(credentials[:password])
end

def default_office_location
  {
  address1: "623a Spalding Ct",
  address2: "Suite 200",
  city: "AnyCity",
  state: Settings.aca.state_abbreviation,
  zip: "01001",
  county: 'Hampden',
  phone_area_code: "202",
  phone_number: "1110000",
  phone_extension: "1111"
  }
end

def non_dc_office_location
  {
  address1: "623a Spalding Ct",
  address2: "Suite 200",
  city: "Falls Church",
  state: "MA",
  zip: "22045",
  phone_area_code: "202",
  phone_number: "1110000",
  phone_extension: "1111"
  }
end

Given(/^User has existing security questions/) do

end

Given(/^Hbx Admin exists$/) do
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true,
                            list_enrollments: true, send_broker_agency_message: true, approve_broker: true, approve_ga: true,
                            modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true, can_lock_unlock: true,
                            can_reset_password: true, view_the_configuration_tab: true, can_access_new_consumer_application_sub_tab: true)
  person = people['Hbx Admin']
  hbx_profile = FactoryBot.create :hbx_profile
  user = FactoryBot.create :user, :with_family, :hbx_staff, with_security_questions: false, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryBot.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  #Hackity Hack need both years reference plans b/c of Plan.valid_shop_dental_plans and Plan.by_active_year(params[:start_on]).shop_market.health_coverage.by_carrier_profile(@carrier_profile).and(hios_id: /-01/)
  year = (Date.today + 2.months).year
  year = (Date.today + 2.months).year
  plan = FactoryBot.create :plan, :with_premium_tables, :with_rating_factors, active_year: year, market: 'shop', coverage_kind: 'health', deductible: 4000
  plan2 = FactoryBot.create :plan, :with_premium_tables, :with_rating_factors, active_year: (year - 1), market: 'shop', coverage_kind: 'health', deductible: 4000, carrier_profile_id: plan.carrier_profile_id
end

Given(/^a Hbx admin with read and write permissions and broker agencies$/) do
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true)
  person = people['Hbx AdminEnrollments']
  hbx_profile = FactoryBot.create :hbx_profile
  user = FactoryBot.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryBot.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryBot.create :hbx_enrollment, household:user.primary_family.active_household
  org1 = FactoryBot.create(:organization, legal_name: 'ACME Agency')
  broker_agency_profile1 = FactoryBot.create(:broker_agency_profile, organization: org1)
        org2 = FactoryBot.create(:organization, legal_name: 'Chase & Assoc')
        broker_agency_profile2 = FactoryBot.create(:broker_agency_profile, organization: org2)
end

Given(/^a Hbx admin with read and write permissions exists$/) do
  #Note: creates an enrollment for testing purposes in the UI
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true, can_add_sep: true)
  person = people['Hbx Admin']
  hbx_profile = FactoryBot.create :hbx_profile
  user = FactoryBot.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryBot.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryBot.create :hbx_enrollment, household:user.primary_family.active_household
end

Given(/^a Hbx admin with super admin access exists$/) do
  #Note: creates an enrollment for testing purposes in the UI
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true, can_complete_resident_application: true)
  person = people['Hbx Admin']
  hbx_profile = FactoryBot.create :hbx_profile, :no_open_enrollment_coverage_period
  user = FactoryBot.create :user, :with_family, :with_hbx_staff_role, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryBot.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryBot.create :hbx_enrollment, household:user.primary_family.active_household
end

Given(/^a Hbx admin with read only permissions exists$/) do
  #Note: creates an enrollment for testing purposes in the UI
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: false)
  person = people['Hbx Admin']
  hbx_profile = FactoryBot.create :hbx_profile
  user = FactoryBot.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryBot.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryBot.create :hbx_enrollment, household:user.primary_family.active_household
end

Given(/^(.*)Employer for (.*) exists with a published health plan year$/) do |kind, named_person|
  person = people[named_person]
  FactoryBot.create(:rating_area, zip_code: "01002", county_name: "Franklin", rating_area: Settings.aca.rating_areas.first)
  organization = FactoryBot.create :organization, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  employer_profile = FactoryBot.create :employer_profile, organization: organization
  owner = FactoryBot.create :census_employee, :owner, employer_profile: employer_profile
  employee = FactoryBot.create :census_employee, employer_profile: employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date]
  plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, fte_count: 2, aasm_state: :published
  benefit_group = FactoryBot.create :benefit_group, plan_year: plan_year
  carrier_profile = benefit_group.reference_plan.carrier_profile
  sic_factors = SicCodeRatingFactorSet.new(active_year: TimeKeeper.date_of_record.year, default_factor_value: 1.0, carrier_profile: carrier_profile).tap do |factor_set|
    factor_set.rating_factor_entries.new(factor_key: employer_profile.sic_code, factor_value: 1.0)
  end
  sic_factors.save!
  group_size_factors = EmployerGroupSizeRatingFactorSet.new(active_year: TimeKeeper.date_of_record.year, default_factor_value: 1.0, max_integer_factor_key: 5, carrier_profile: carrier_profile).tap do |factor_set|
    [0..5].each do |size|
      factor_set.rating_factor_entries.new(factor_key: size, factor_value: 1.0)
    end
  end
  group_size_factors.save!
  employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

Given(/^Employer for (.*) exists with a published plan year offering health and dental$/) do |named_person|
  person = people[named_person]
  FactoryBot.create(:rating_area, zip_code: "01002", county_name: "Franklin", rating_area: Settings.aca.rating_areas.first)
  organization = FactoryBot.create :organization, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  employer_profile = FactoryBot.create :employer_profile, organization: organization
  owner = FactoryBot.create :census_employee, :owner, employer_profile: employer_profile
  employee = FactoryBot.create :census_employee, employer_profile: employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date]

  plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, fte_count: 2, aasm_state: :published
  benefit_group = FactoryBot.create :benefit_group, :with_valid_dental, plan_year: plan_year
  carrier_profile = benefit_group.dental_reference_plan.carrier_profile #THIS FIXES empty SicCodeRatingFactorSet from plan shopping show controller but... WHY???
  sic_factors = SicCodeRatingFactorSet.new(active_year: TimeKeeper.date_of_record.year, default_factor_value: 1.0, carrier_profile: carrier_profile).tap do |factor_set|
    factor_set.rating_factor_entries.new(factor_key: employer_profile.sic_code, factor_value: 1.0)
  end
  sic_factors.save!
  group_size_factors = EmployerGroupSizeRatingFactorSet.new(active_year: TimeKeeper.date_of_record.year, default_factor_value: 1.0, max_integer_factor_key: 5, carrier_profile: carrier_profile).tap do |factor_set|
    [0..5].each do |size|
      factor_set.rating_factor_entries.new(factor_key: size, factor_value: 1.0)
    end
  end
  group_size_factors.save!
  employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  Caches::PlanDetails.load_record_cache!
end

Given(/(.*) Employer for (.*) exists with active and renewing plan year/) do |kind, named_person|
  person = people[named_person]
  FactoryBot.create(:rating_area, zip_code: "01002", county_name: "Franklin", rating_area: Settings.aca.rating_areas.first)
  organization = FactoryBot.create :organization, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  employer_profile = FactoryBot.create :employer_profile, organization: organization, profile_source: (kind.downcase == 'conversion' ? kind.downcase : 'self_serve'), registered_on: TimeKeeper.date_of_record
  owner = FactoryBot.create :census_employee, :owner, employer_profile: employer_profile
  employee_role = FactoryBot.create(:employee_role, employer_profile: organization.employer_profile)
  owner.update_attributes!(employee_role_id: employee_role.id)
  employee = FactoryBot.create :census_employee, employer_profile: employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date],
    email: FactoryBot.build(:email, address: person[:email])


  earliest_enrollment_available = TimeKeeper.date_of_record.next_month.beginning_of_month

  open_enrollment_start_on = earliest_enrollment_available + 1.day
  open_enrollment_end_on = open_enrollment_start_on + 12.days
  start_on = open_enrollment_start_on.next_month.beginning_of_month
  end_on = start_on.next_year.prev_day

  renewal_plan = FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01")
  plan = FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.prev_year.year, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id)

  plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, start_on: start_on - 1.year, end_on: end_on - 1.year,
    open_enrollment_start_on: open_enrollment_start_on - 1.year, open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days,
    fte_count: 2, aasm_state: :published, is_conversion: (kind.downcase == 'conversion' ? true : false)

  benefit_group = FactoryBot.create :benefit_group, plan_year: plan_year, reference_plan_id: plan.id
  employee.add_benefit_group_assignment benefit_group, benefit_group.start_on

  renewal_plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on, fte_count: 2, aasm_state: :renewing_draft
  renewal_benefit_group = FactoryBot.create :benefit_group, plan_year: renewal_plan_year, reference_plan_id: renewal_plan.id
  employee.add_renew_benefit_group_assignment renewal_benefit_group

  FactoryBot.create(:qualifying_life_event_kind, market_kind: "shop")
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

Given(/(.*) Employer for (.*) exists with active and expired plan year/) do |kind, named_person|
  person = people[named_person]
  FactoryBot.create(:rating_area, zip_code: "01002", county_name: "Franklin", rating_area: Settings.aca.rating_areas.first)
  organization = FactoryBot.create :organization, :with_expired_and_active_plan_years, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  organization.employer_profile.update_attributes(profile_source: (kind.downcase == 'conversion' ? kind.downcase : 'self_serve'), registered_on: TimeKeeper.date_of_record)
  owner = FactoryBot.create :census_employee, :owner, employer_profile: organization.employer_profile
  employee = FactoryBot.create :census_employee, employer_profile: organization.employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date],
    hired_on: TimeKeeper.date_of_record - 15.months
  employee_role = FactoryBot.create(:employee_role, employer_profile: organization.employer_profile)
  employee.update_attributes(employee_role_id: employee_role.id)
  expired_bg = organization.employer_profile.plan_years.where(aasm_state: "expired").first.benefit_groups.first
  employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group_id: expired_bg.id, start_on: expired_bg.start_on)

  FactoryBot.create(:qualifying_life_event_kind, market_kind: "shop")
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

Given(/(.*) Employer for (.*) exists with active and renewing enrolling plan year/) do |kind, named_person|
  person = people[named_person]
  FactoryBot.create(:rating_area, zip_code: "01002", county_name: "Franklin", rating_area: Settings.aca.rating_areas.first)
  organization = FactoryBot.create :organization, :with_active_and_renewal_plan_years, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  organization.employer_profile.update_attributes(profile_source: (kind.downcase == 'conversion' ? kind.downcase : 'self_serve'), registered_on: TimeKeeper.date_of_record)
  owner = FactoryBot.create :census_employee, :owner, employer_profile: organization.employer_profile
  employee = FactoryBot.create :census_employee, employer_profile: organization.employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date],
    hired_on: TimeKeeper.date_of_record - 15.months
  employee_role = FactoryBot.create(:employee_role, employer_profile: organization.employer_profile)
  employee.update_attributes(employee_role_id: employee_role.id)
  renewing_bg = organization.employer_profile.plan_years.where(aasm_state: "renewing_enrolling").first.benefit_groups.first
  employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group_id: renewing_bg.id, start_on: renewing_bg.start_on)

  FactoryBot.create(:qualifying_life_event_kind, market_kind: "shop")
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

When(/(^.+) enters? office location for (.+)$/) do |role, location|
  location = eval(location) if location.class == String
  RatingArea.where(zip_code: "01001").first || FactoryBot.create(:rating_area, zip_code: "01001", county_name: "Hampden", rating_area: Settings.aca.rating_areas.first)
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][address_1]', :with => location[:address1]
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][address_2]', :with => location[:address2]
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][city]', :with => location[:city]

  # find(:xpath, "//div[contains(@class, 'selectric')][p[contains(text(), 'SELECT STATE')]]").click
  select "MA", from: "inputState"
  # agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][state]
  # find(:xpath, "//div[contains(@class, 'selectric-scroll')]/ul/li[contains(text(), '#{location[:state]}')]").click
  select "Primary", from: "kindSelect"
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][zip]', :with => location[:zip]
  if role.include? 'Employer'
    wait_for_ajax
    select "#{location[:county]}", :from => "agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][county]"
  end
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][area_code]', :with => location[:phone_area_code]
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][number]', :with => location[:phone_number]
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][extension]', :with => location[:phone_extension]
  find('#broker-btn').click
end

When(/^.+ updates office location from (.+) to (.+)$/) do |old_add, new_add|
  old_add = eval(old_add) if old_add.class == String
  new_add = eval(new_add) if new_add.class == String
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_1]', :with => new_add[:address1]
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_2]', :with => new_add[:address2]
  fill_in 'organization[office_locations_attributes][0][address_attributes][city]', :with => new_add[:city]

  find(:xpath, "//div[contains(@class, 'selectric')][p[contains(text(), '#{old_add[:state]}')]]").click
  find(:xpath, "//div[contains(@class, 'selectric-scroll')]/ul/li[contains(text(), '#{new_add[:state]}')]").click

  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', :with => new_add[:zip]
end

When(/^(.+) creates? a new employer profile with (.+)$/) do |named_person, primary_location|
  employer = people[named_person]
  fill_in 'organization[first_name]', :with => employer[:first_name]
  fill_in 'organization[last_name]', :with => employer[:last_name]
  fill_in 'jq_datepicker_ignore_organization[dob]', :with => employer[:dob]

  find('#organization_legal_name').click
  fill_in 'organization[legal_name]', :with => employer[:legal_name]
  fill_in 'organization[dba]', :with => employer[:dba]
  fill_in 'organization[fein]', :with => employer[:fein]
  select_from_chosen '0111', from: 'Select Industry Code'

  find('.selectric-interaction-choice-control-organization-entity-kind').click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'C Corporation')]").click

  find(:xpath, "//select[@name='organization[entity_kind]']/option[@value='c_corporation']")
  step "I enter office location for #{primary_location}"
  fill_in 'organization[email]', :with => Forgery('email').address
  fill_in 'organization[area_code]', :with => '202'
  fill_in 'organization[number]', :with => '5551212'
  fill_in 'organization[extension]', :with => '22332'
  find(:xpath, "//div[contains(@class, 'selectric')][p[contains(text(), 'Only Electronic communications')]]").click
  find(:xpath, "//select[@name='organization[contact_method]']/option[@value='Paper and Electronic communications']")

  find('.interaction-click-control-save').click
end

When(/^(.*) logs on to the (.*)?/) do |named_person, portal|
  person = people[named_person]

  visit "/"
  portal_class = "#{portal.downcase.gsub(/ /, '-')}"
  portal_uri = find("a.#{portal_class}")["href"]

  visit "/users/sign_in"
  fill_in "user[login]", :with => person[:email]
  find('#user_login').set(person[:email])
  fill_in "user[password]", :with => person[:password]
  #TODO this fixes the random login fails b/c of empty params on email
  fill_in "user[login]", :with => person[:email] unless find(:xpath, '//*[@id="user_login"]').value == person[:email]
  find('.sign-in-btn').click
  visit portal_uri
  # Adding sleep seems to help prevent the AuthenticityToken error
  # which apeared to be throwing in at least the
  # add_sep_read_and_write_feature cucumber.
end

When(/^user visits the (.*)?/) do |portal|
  visit "/"
  portal_class = "#{portal.downcase.gsub(/ /, '-')}"
  portal_uri = find("a.#{portal_class}")["href"]
  sleep 10
  visit portal_uri
end

Then(/^.+ creates (.+) as a roster employee$/) do |named_person|
  person = people[named_person]
  screenshot("create_census_employee")
  fill_in 'census_employee[first_name]', :with => person[:first_name]
  fill_in 'census_employee[last_name]', :with => person[:last_name]
  fill_in 'jq_datepicker_ignore_census_employee[dob]', :with => person[:dob]
  fill_in 'census_employee[ssn]', :with => person[:ssn]

  find('label[for=census_employee_gender_male]').click
  fill_in 'jq_datepicker_ignore_census_employee[hired_on]', with: (Time.now - 1.week).strftime('%m/%d/%Y')
  find(:xpath, '//label[input[@name="census_employee[is_business_owner]"]]').click

  fill_in 'census_employee[address_attributes][address_1]', :with => '1026 Potomac'
  fill_in 'census_employee[address_attributes][address_2]', :with => 'Apt ABC'
  fill_in 'census_employee[address_attributes][city]', :with => 'Alpharetta'
  find(:xpath, '//p[@class="label"][contains(., "SELECT STATE")]').click
  find(:xpath, '//div[div/p[contains(., "SELECT STATE")]]//li[contains(., "GA")]').click
  fill_in 'census_employee[address_attributes][zip]', :with => '30228'
  find(:xpath, '//p[@class="label"][contains(., "SELECT KIND")]').click
  find(:xpath, '//div[div/p[contains(., "SELECT KIND")]]//li[contains(., "home")]').click

  fill_in 'census_employee[email_attributes][address]', with: 'broker.assist@dc.gov'
  screenshot("broker_create_census_employee_with_data")
  find('.interaction-click-control-create-employee').click
end

Given(/^(.+) has not signed up as an HBX user$/) do |actor|
  step "I use unique values"
end

When(/^.* visit the Employer portal$/) do
  visit "/"
  page.click_link 'Employer Portal'
  screenshot("employer_start")
end

Then(/^(?:.+) should see a successful sign up message$/) do
  FactoryBot.create(:sic_code, sic_code: "0111")
  expect(page).to have_content("Welcome!")
  screenshot("employer_sign_up_welcome")
end

Then(/^(?:.+) should click on employer portal$/) do
  visit "/"
  screenshot("start")
  page.click_link 'Employer Portal'
  screenshot("employee_portal")
end

When(/^(?:.+) go(?:es)? to the employee account creation page$/) do
  visit "/"
  click_link 'Employee Portal'
end

And(/^employee visits the Employee Portal page$/) do
  visit "/"
  click_link 'Employee Portal'
end

Then(/^(?:.+) should be logged on as an unlinked employee$/) do
  screenshot("logged_in_welcome")
  @browser.a(href: /consumer\/employee\/search/).wait_until_present
  screenshot("logged_in_welcome")
  expect(@browser.a(href: /consumer.employee.search/).visible?).to be_truthy
end

When (/^(.*) logs? out$/) do |someone|
  click_link "Logout"
  visit "/"
  sleep 5 #FIX ME: remove sleep and replace with find & wait
end

When(/^.+ go(?:es)? to register as an employee$/) do
  # find("option[id='sec-answer-0-0']").click
  # find("option[id='sec-answer-0-1']").click
  # find("option[id='sec-answer-0-2']").click
  # click_button('Save Responses')
  sleep 1
  find('.interaction-click-control-continue').click
end

Then(/^.+ should see the employee search page$/) do
  wait_for_ajax(2, 2)
  sleep(1)
  expect(find('.interaction-field-control-person-first-name')).to be_visible
  screenshot("employer_search")
end

Given(/^(.*) visits the employee portal$/) do |named_person|
  visit "/insured/employee/privacy"
end

Then(/^.+ should see the employee privacy text$/) do
  click_link "CONTINUE"
end

When(/^(.*) creates an HBX account$/) do |named_person|
  screenshot("start")

  person = people[named_person]

  fill_in "user[oim_id]", :with => person[:email]
  fill_in "user[password_confirmation]", :with => person[:password]
  fill_in "user[password]", :with => person[:password]
  find('.create-account-btn').click
end

And(/^Primary Broker select the all security question and give the answer$/) do
  step 'I select the all security question and give the answer'
end

When(/^Primary Broker have submit the security questions$/) do
  step 'I have submitted the security questions'
end

And(/^Broker Assisted select the all security question and give the answer$/) do
  step 'I select the all security question and give the answer'
end

When(/^Broker Assisted have submit the security questions$/) do
  step 'I have submitted the security questions'
end

When(/^.+ enters? the identifying info of (.*)$/) do |named_person|
  person = people[named_person]
  person_ssn = "#{person[:ssn][0..2]}-#{person[:ssn][3..4]}-#{person[:ssn][5..8]}"

  fill_in 'person[first_name]', :with => person[:first_name]
  fill_in 'person[last_name]', :with => person[:last_name]
  fill_in 'jq_datepicker_ignore_person[dob]', :with => person[:dob]
  fill_in 'person[ssn]', :with => person_ssn
  find(:xpath, '//label[@for="radio_male"]').click

  screenshot("information_entered")
  find('.interaction-click-control-continue').click
end

And(/^(.*?) sees the option to enroll for all employers$/) do |named_person|
  @organization.keys.each do |legal_name|
    expect(page).to have_content("Enroll as an employee of " + legal_name)
  end
end

Then(/^.+ should not see the matched employee record form$/) do
  find('.fa-exclamation-triangle')
  expect(page).to_not have_css('.interaction-click-control-this-is-my-employer')
end

Then(/^Employee should see the matched employee record form$/) do
  expect(page).to have_content(employer.legal_name)
  screenshot("employer_search_results")
end

Then(/^Employee should see the shop market place workflow as default$/) do
  within('.select-employer') do
    expect(page).to have_content('Enroll as an employee of Acme Inc.')
  end
end

Then(/^Employee should not see the individual market place workflow$/) do
  within('.select-employer') do
    expect(page).not_to have_css('#individual-benefits')
  end
end

Given(/^Employer exists and logs in and adds and employee$/) do
  login_as @staff_role
end

# TODO: needs to be merged
Then(/^.+ should see the matching employee record form$/) do
  expect(page).to have_content('Turner Agency')
  screenshot("employer_search_results")
end

When(/^.+ accepts? the matched employer$/) do
  screenshot("update_personal_info")
  find_by_id('btn-continue').click
end

Then(/^Employee (.+) should see coverage effective date/) do |named_person|
  census_employee = CensusEmployee.where(:first_name => /#{people[named_person][:first_name]}/i, :last_name => /#{people[named_person][:last_name]}/i).first
  find('p', text: census_employee.benefit_sponsorship.legal_name, wait: 10)
  find('.coverage_effective_date', text: census_employee.earliest_eligible_date.strftime("%m/%d/%Y"))
end

When(/^.+ completes? the matched employee form for (.*)$/) do |named_person|

  # Sometimes bombs due to overlapping modal
  # TODO: fix this bombing issue
  wait_for_ajax
  page.evaluate_script("window.location.reload()")
  wait_for_ajax(3,2)
  person = people[named_person]
  # screenshot("before modal")
  # # find('.interaction-click-control-click-here').click
  # screenshot("during modal")
  # # find('.interaction-click-control-close').click
  # screenshot("after modal")
  expect(page).to have_css('input.interaction-field-control-person-phones-attributes-0-full-phone-number')
  wait_for_ajax(3,2)

  #find("#person_addresses_attributes_0_address_1", :wait => 10).click
  # find("#person_addresses_attributes_0_address_1").click
  # find("#person_addresses_attributes_0_address_2").click
  # there is a flickering failure here due to over-lapping modals
  # find("#person_addresses_attributes_0_city").click
  # find("#person_addresses_attributes_0_zip").click
  find_by_id("person_phones_attributes_0_full_phone_number", wait: 10)
  wait_for_ajax
  phone_number = "(#{person[:home_phone][0..2]}) #{person[:home_phone][3..5]}-#{person[:home_phone][6..9]}"
  fill_in "person[phones_attributes][0][full_phone_number]", :with => phone_number
  screenshot("personal_info_complete")
  expect(page).to have_field("HOME PHONE", with: phone_number) if person[:home_phone].present?
  find('.interaction-click-control-continue', text: 'CONTINUE', wait: 5).click
end

And(/^.+ sees the (.*) page and clicks Continue$/) do |which_page|
  # Whats the point of the below
  # expect(page).to have_content(which_page)
  continue = find('.interaction-click-control-continue', text: 'CONTINUE', wait:10)
  continue.click
end

And(/^.+ clicks Confirm$/) do
  find_link('Confirm', wait: 10)
  click_link 'Confirm'
end

And(/^.+ selects the first plan available$/) do
  links = page.all('a')
  find('h1', text:'Choose Coverage for your Household', wait: 10)
  find('.interaction-click-control-continue', text: 'CONTINUE').click
  find('.plan-select', match: :first).click
end

Then(/^.+ should see the dependents page$/) do
  find('.interaction-click-control-add-member', wait: 10)
  expect(page).to have_content('Add Member')
  screenshot("dependents_page")
end

When(/^.+ clicks? edit on baby Soren$/) do
  scroll_then_click(@browser.span(text: "07/03/2014").as(xpath: "./preceding::a[contains(@href, 'edit')]").last)
end

Then(/^.+ should see the edit dependent form$/) do
  @browser.button(:text => /Confirm Member/i).wait_until_present
end

When(/^.+ clicks? delete on baby Soren$/) do
  scroll_then_click(@browser.form(id: 'edit_dependent').a())
  @browser.div(id: 'remove_confirm').wait_until_present
  scroll_then_click(@browser.a(class: /confirm/))
  @browser.button(text: /Confirm Member/i).wait_while_present
end

Then(/^.+ should see (\d+) dependents*$/) do |n|
  expect(page).to have_selector('li.dependent_list', :count => n.to_i)
end

When(/^.+ clicks? Add Member$/) do
  click_link("Add Member", :visible => true)
end

Then(/^.+ should see the new dependent form$/) do

  expect(page).to have_content('Confirm Member')
end

When(/^.+ enters? the dependent info of .+ daughter$/) do
  fill_in 'dependent[first_name]', with: 'Cynthia'
  fill_in 'dependent[last_name]', with: 'White'
  date = TimeKeeper.date_of_record - 28.years
  dob = date.to_s
  fill_in 'jq_datepicker_ignore_dependent[dob]', with: dob
  find(:xpath, "//span[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, "//li[@data-index='3'][contains(., 'Child')]").click
  find(:xpath, "//label[@for='radio_female']").click
end

When(/^.+ enters? the dependent info of Patrick wife$/) do
  fill_in 'dependent[first_name]', with: 'Cynthia'
  fill_in 'dependent[last_name]', with: 'Patrick'
  fill_in 'dependent[ssn]', with: '123445678'
  fill_in 'jq_datepicker_ignore_dependent[dob]', with: '01/15/1996'
  find('#dependents_info_wrapper').click
  sleep 1
  find(:xpath, "//span[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, "//li[@data-index='1'][contains(., 'Spouse')]").click
  find(:xpath, "//label[@for='radio_female']").click
  fill_in 'dependent[addresses][0][address_1]', with: '123 STREET'
  fill_in 'dependent[addresses][0][city]', with: 'WASHINGTON'
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[@data-index='24'][contains(., 'MA')]").click
  fill_in 'dependent[addresses][0][zip]', with: '01001'
end

When(/^.+ clicks? confirm member$/) do
  all(:css, ".mz").last.click
  expect(page).to have_link('Add Member')
end

When(/^.+ clicks? continue on the dependents page$/) do
  screenshot("group_selection")
  find('#btn-continue').click
end

Then(/^.+ should see the group selection page$/) do
  find('#group-selection-form', :wait => 10)
  expect(page).to have_css('form')
end

When(/^.+ clicks? health radio on the group selection page$/) do
  find(:xpath, '//label[@for="coverage_kind_dental"]').click
end

# When(/^(?:Employee){0}.+ clicks? continue on the group selection page$/) do
#   find('#btn-continue').click
# end

Then(/^.+ should see the plan shopping welcome page$/) do
  expect(page).to have_content('Choose Plan')
  screenshot("plan_shopping_welcome")
end

Then(/^.+ should see the plan shopping page with no dependent$/) do
  expect(page).to have_content("Soren White")
end

Then(/^.+ should see the plan shopping page with one dependent$/) do
  expect(page).to have_content("Soren White + 1 Dependent")
end

When(/^.+ clicks? continue on the plan shopping welcome page$/) do
  scroll_then_click(@browser.a(text: "Continue"))
end

When(/^.+ clicks? my insured portal link$/) do
  click_link 'My Insured Portal'
end

When(/^.+ clicks? shop for plans button$/) do
  find('.interaction-click-control-shop-for-plans', wait: 5).click
end

When(/^.+ clicks Shop for new plan button$/) do
  find('.interaction-click-control-shop-for-new-plan', wait: 5).click
end

Then(/^.+ should see the list of plans$/) do
  find('#planContainer', wait: 10)
  expect(page).to have_link('Select')
  screenshot("plan_shopping")
end

And (/(.*) should see the plans from the (.*) plan year$/) do |named_person, plan_year_state|
  benefit_sponsorship = CensusEmployee.where(first_name: people[named_person][:first_name]).first.benefit_sponsorship
  # cannot select a SEP date from expired plan year on 31st.
  if TimeKeeper.date_of_record.day != 31 || plan_year_state != "expired"
    expect(page).to have_content benefit_sponsorship.benefit_applications.where(aasm_state: plan_year_state.to_sym).first.benefit_packages.first.health_sponsored_benefit.reference_product.name
  else
    expect(page).to have_content benefit_sponsorship.benefit_applications.where(:aasm_state.ne => plan_year_state.to_sym).first.benefit_packages.first.health_sponsored_benefit.reference_product.name
  end
end

When(/^.+ selects? a plan on the plan shopping page$/) do
  find_all('.interaction-click-control-select-plan', wait: 5)[0].click
end

Then(/^.+ should see the coverage summary page$/) do
  expect(page).to have_content('Confirm Your Plan Selection')
  screenshot("summary_page")
end

When(/^.+ clicks? on Confirm button on the coverage summary page$/) do
  find('.interaction-click-control-confirm', wait: 5).click
end

Then(/^.+ should see the receipt page$/) do
  expect(page).to have_content('Enrollment Submitted')
  screenshot("receipt_page")
  find('.interaction-click-control-continue').click
end

Then(/^.+ should see the "my account" page$/) do
  find('.my-account-page', wait: 10)
  expect(page).to have_content("My #{Settings.site.short_name}")
  screenshot("my_account")
end

Then(/^.+ should see the "Your Enrollment History" section/) do
  @browser.element(text: /YOUR ENROLLMENT HISTORY/i).wait_until_present
  expect(@browser.element(text: /YOUR ENROLLMENT HISTORY/i).visible?).to be_truthy
end

When(/^.+ clicks? a qle event$/) do
  scroll_then_click(@browser.a(text: /Divorce/))
  @browser.text_field(class: "interaction-field-control-qle-date").set((Date.today + 5).strftime("%m/%d/%Y"))
  scroll_then_click(@browser.a(class: /interaction-click-control-submit/))
  @browser.element(text: /You may be eligible for a special enrollment period./i).wait_until_present
  expect(@browser.element(text: /You may be eligible for a special enrollment period./i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/))
  @browser.element(text: /Household Info: Family Members/i).wait_until_present
  expect(@browser.element(text: /Household Info: Family Members/i).visible?).to be_truthy
  scroll_then_click(@browser.a(id: /btn_household_continue/))
  @browser.element(text: /Choose Benefits: Covered Family Members/i).wait_until_present
  expect(@browser.element(text: /Choose Benefits: Covered Family Members/i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-keep-existing-plan/))
end

Then(/^.+ can purchase a plan$/) do
  @browser.element(text: /Confirm Your Plan Selection/i).wait_until_present
  expect(@browser.element(text: /Confirm Your Plan Selection/i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-purchase/))
  @browser.element(text: /Purchase confirmation/i).wait_until_present
  expect(@browser.element(text: /Purchase confirmation/i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/))
  @browser.element(text: /Your PLAN/i).wait_until_present
  expect(@browser.element(text: /YOUR PLAN/i).visible?).to be_truthy
end

When(/^Employer publishes a plan year$/) do
  find('.interaction-click-control-benefits').click

  find('.interaction-click-control-publish-plan-year').click
end

When(/^.+ should see a published success message$/) do
  expect(find('.alert')).to have_content('Plan Year successfully published')
end

When(/^.+ goes to to home tab$/) do
  @browser.element(class: /interaction-click-control-my-dc-health-link/).fire_event('onclick')
end

Then(/^.+ should see the current plan year$/) do
  @browser.element(text: /My Health Benefits Program/i).wait_until_present
  # expect(@browser.h5(text: /Plan Year/i).visible?).to be_truthy
end

And(/^.+ should see the premium billings report$/) do
  # expect(@browser.h3(text: /Enrollment Report/i).visible?).to be_truthy
end

When(/^.+ should see a published success message without employee$/) do
  # TODO: Fix checking for flash messages. We will need to check using
  #       xpath for an element that may not be visible, but has already
  #       been faded away by jQuery.
  wait_for_ajax
  expect(page).to have_content('You have 0 non-owner employees on your roster')
end

When(/^.+ clicks? on the add employee button$/) do
  evaluate_script(<<-JSCODE)
  $('.interaction-click-control-add-new-employee')[0].click()
  JSCODE
  wait_for_ajax
end

When(/^.+ clicks? to add the first employee$/) do
  find('.interaction-click-control-add-new-employee', :wait => 10).click
end

When(/^(?:General){0}.+ clicks? on the ((?:General|Staff){0}.+) tab$/) do |tab_name|
  find(:xpath, "//li[contains(., '#{tab_name}')]", :wait => 10).click
  wait_for_ajax
end

When(/^(?:General){0}.+ clicks? on the ((?:General|Staff){0}.+) dropdown$/) do |tab_name|
  target_dropdown = page.all('a').detect { |a| a.text == tab_name }
  target_dropdown.click
  wait_for_ajax
end

When(/^(?:General){0}.+ clicks? on the ((?:General|Staff){0}.+) option$/) do |tab_name|
  find(".interaction-click-control-#{tab_name.downcase.gsub(' ','-')}", wait: 5).click
  wait_for_ajax
  find('#myTabContent').click
end

And(/^clicks on the person in families tab$/) do
  login_as hbx_admin
  visit exchanges_hbx_profiles_root_path
  page.find('.families.dropdown-toggle.interaction-click-control-families').click
  find(:xpath, "//a[@href='/exchanges/hbx_profiles/family_index_dt']").click
  wait_for_ajax(10,2)
  family_member = page.find('a', :text => "#{user.person.full_name}")
  family_member.click
  visit verification_insured_families_path
  find(:xpath, "//ul/li/a[contains(@class, 'interaction-click-control-documents')]").click
end

When(/^.+ clicks? on the tab for (.+)$/) do |tab_name|
  @browser.element(class: /interaction-click-control-#{tab_name}/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-#{tab_name}/))
end

When(/^I click the "(.*?)" in qle carousel$/) do |qle_event|
  click_link "#{qle_event}"
end

When(/^I click on "(.*?)" button on household info page$/) do |select_action|
  click_link "Continue"
  click_button "Shop for new plan"
end

When(/^I click on continue on qle confirmation page$/) do
  expect(page).to have_content "Enrollment Submitted"
  screenshot("qle_confirm")
  click_link "GO TO MY ACCOUNT"
end


When(/^I select a future qle date$/) do
  expect(page).to have_content "Married"
  screenshot("future_qle_date")
  fill_in "qle_date", :with => (TimeKeeper.date_of_record + 5.days).strftime("%m/%d/%Y")
  click_link "CONTINUE"
end

Then(/^I should see not qualify message$/) do
  expect(page).to have_content "The date you submitted does not qualify for special enrollment"
  screenshot("not_qualify")
end

When(/^I select a past qle date$/) do
  expect(page).to have_content "Married"
  screenshot("past_qle_date")
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  find(".navbar-brand").click #to stop datepicker blocking shit
  within '#qle-date-chose' do
    click_link "CONTINUE"
  end
end

Then(/^I should see confirmation and continue$/) do
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  screenshot("valid_qle")
  click_button "Continue"
end

Then(/^I can click on Shop for Plan button$/) do
  click_button "Shop for Plans"
end

Then(/^Page should contain existing qle$/) do
  expect(page).to have_content 'You qualify for a Special Enrollment Period (SEP) because you "Married"'
end

Then(/^I can click Shop with existing SEP link$/) do
  click_link "Shop Now"
end

Then(/^I should see the dependents and group selection page$/) do
  #@browser.element(text: /Household Info: Family Members/i).wait_until_present
  expect(@browser.element(text: /Household Info: Family Members/i).visible?).to be_truthy
  @browser.element(class: /interaction-click-control-continue/).wait_until_present
  @browser.execute_script("$('.interaction-click-control-continue')[1].click();")
  @browser.element(text: /Choose Benefits: Covered Family Members/i).wait_until_present
  expect(@browser.element(text: /Choose Benefits: Covered Family Members/i).visible?).to be_truthy
  scroll_then_click(@browser.button(class: /interaction-click-control-shop-for-new-plan/))
  @browser.element(text: /Choose Plan/i).wait_until_present
  expect(@browser.element(text: /Choose Plan/i).visible?).to be_truthy
  @browser.execute_script("$('.interaction-click-control-select-plan')[1].click()")
  @browser.element(text: /Confirm Your Plan Selection/i).wait_until_present
  expect(@browser.element(text: /Confirm Your Plan Selection/i).visible?).to be_truthy
  scroll_then_click(@browser.a(class: /interaction-click-control-purchase/))
end

And(/I select three plans to compare/) do
  wait_for_ajax
  expect(page).to have_content("Select Plan")
  if page.all("span.checkbox-custom-label").count > 3
    #modal plan data for IVL not really seeded in.
    page.all("span.checkbox-custom-label")[0].click
    page.all("span.checkbox-custom-label")[1].click
    page.all("span.checkbox-custom-label")[2].click
    all('.compare-selected-plans-link')[1].click

    wait_for_ajax(10)
    expect(page).to have_content("Choose Plan - Compare Selected Plans")
    find(:xpath, '//*[@id="plan-details-modal-body"]/div[2]/button[2]').click
  end
end

And(/I should not see any plan which premium is 0/) do
  page.all("h2.plan-premium").each do |premium|
    expect(premium).not_to have_content("$0.00")
  end
end

And(/^.+ clicks on the link of New Employee Paper Application$/) do
  find('.new_employee_paper_application').click
end

Then (/HBX admin start new employee enrollment/) do
  expect(page).to have_content("Personal Information")
end

Then(/Employee should see the correct employee contribution on plan tile/) do
  enrollment = Person.all.first.primary_family.active_household.hbx_enrollments.where(:"aasm_state".ne => "shopping").first
  expect(page).to have_content "$#{enrollment.total_employee_cost.round(2)}"
end

Then(/Employee should see their current plan/) do
  expect(page).to have_content "YOUR CURRENT #{TimeKeeper.date_of_record.year} PLAN"
end

Then("user will click on New Employee Paper Application link") do
  find('.new_employee_paper_application').click
end

And(/(.*) should have a ER sponsored enrollment/) do |named_person|
  person = people[named_person]
  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  ce.save # to update benefit group assignment that needs to updated.
  person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first
  benefit_package = ce.active_benefit_group_assignment.benefit_package
  FactoryBot.create(:hbx_enrollment,
                     household: person_rec.primary_family.active_household,
                     coverage_kind: "health",
                     effective_on: benefit_package.start_on,
                     enrollment_kind: "open_enrollment",
                     kind: "employer_sponsored",
                     submitted_at: benefit_package.start_on - 20.days,
                     employee_role_id: person_rec.active_employee_roles.first.id,
                     benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
                     benefit_sponsorship_id: ce.benefit_sponsorship.id,
                     sponsored_benefit_package_id: benefit_package.id,
                     sponsored_benefit_id: benefit_package.health_sponsored_benefit.id,
                     rating_area_id: benefit_package.rating_area.id,
                     product_id: benefit_package.health_sponsored_benefit.reference_product_id,
                     issuer_profile_id: benefit_package.health_sponsored_benefit.products(benefit_package.start_on).first.issuer_profile.id)
end

Then(/Devops can verify session logs/) do
  log_entries = `tail -n 15 log/test.log`.split("\n")
  #log with a logged out session
  session_id = log_entries.last.match(/\[([^\]]*)\]/)[1]
  session_history = SessionIdHistory.where(session_id: session_id).first
  expect(session_history.present?).to be true
  expect(session_history.session_user_id).to be nil
  #earlier in log was logged on
  logged_on_session = SessionIdHistory.all[-2]
  user = User.find(logged_on_session.session_user_id)
  expect(log_entries.first).to match(/#{logged_on_session.session_id}/)
  #user was a consumer
  expect(user.person.consumer_role).not_to be nil
end

Given(/^(.*) admin user with read and write permissions present/) do |hbx_admin_person|
  p_staff = FactoryBot.create(:permission, :hbx_update_ssn)
  hbx_profile = FactoryBot.create(:hbx_profile)
  person = people[hbx_admin_person]
  user = FactoryBot.create(:user,
    :with_family,
    :hbx_staff,
    email: person[:email],
    password: person[:password],
    password_confirmation: person[:password]
  )
  FactoryBot.create(:hbx_staff_role,
    person: user.person,
    hbx_profile: hbx_profile,
    permission_id: p_staff.id
  )
end

And(/^Hbx Admin click on Employers/) do
  find_link("Employers").visible?
  click_link("Employers")
end
