require 'pry'
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
      fein: "764141112",
      mlegal_name: "Cogswell Cogs, Inc",
      mdba: "Cogswell Cogs, Inc",
      mfein: "211141467"
    },
    "Patrick Doe" => {
      first_name: "Patrick",
      last_name: "Doe",
      dob: "01/01/1980",
      ssn: "786120965",
      email: 'patrick.doe@dc.gov',
      password: 'aA1!aA1!aA1!'
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
  city: "Washington",
  state: "DC",
  zip: "20001",
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
  state: "VA",
  zip: "22045",
  phone_area_code: "202",
  phone_number: "1110000",
  phone_extension: "1111"
  }
end

Given(/^Hbx Admin exists$/) do
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true)
  person = people['Hbx Admin']
  hbx_profile = FactoryGirl.create :hbx_profile
  user = FactoryGirl.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryGirl.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  #Hackity Hack need both years reference plans b/c of Plan.valid_shop_dental_plans and Plan.by_active_year(params[:start_on]).shop_market.health_coverage.by_carrier_profile(@carrier_profile).and(hios_id: /-01/)
  year = (Date.today + 2.months).year
  year = (Date.today + 2.months).year
  plan = FactoryGirl.create :plan, :with_premium_tables, active_year: year, market: 'shop', coverage_kind: 'health', deductible: 4000
  plan2 = FactoryGirl.create :plan, :with_premium_tables, active_year: (year - 1), market: 'shop', coverage_kind: 'health', deductible: 4000, carrier_profile_id: plan.carrier_profile_id
end

Given(/^a Hbx admin with read and write permissions and broker agencies$/) do
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true)
  person = people['Hbx AdminEnrollments']
  hbx_profile = FactoryGirl.create :hbx_profile
  user = FactoryGirl.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryGirl.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryGirl.create :hbx_enrollment, household:user.primary_family.active_household
  org1 = FactoryGirl.create(:organization, legal_name: 'ACME Agency')
  broker_agency_profile1 = FactoryGirl.create(:broker_agency_profile, organization: org1)
        org2 = FactoryGirl.create(:organization, legal_name: 'Chase & Assoc')
        broker_agency_profile2 = FactoryGirl.create(:broker_agency_profile, organization: org2)
end

Given(/^a Hbx admin with read and write permissions exists$/) do
  #Note: creates an enrollment for testing purposes in the UI
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true)
  person = people['Hbx Admin']
  hbx_profile = FactoryGirl.create :hbx_profile
  user = FactoryGirl.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryGirl.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryGirl.create :hbx_enrollment, household:user.primary_family.active_household
end

Given(/^a Hbx admin with super admin access exists$/) do
  #Note: creates an enrollment for testing purposes in the UI
  p_staff = Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true, can_complete_resident_application: true)
  person = people['Hbx Admin']
  hbx_profile = FactoryGirl.create :hbx_profile, :no_open_enrollment_coverage_period
  user = FactoryGirl.create :user, :with_family, :with_hbx_staff_role, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryGirl.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryGirl.create :hbx_enrollment, household:user.primary_family.active_household
end

Given(/^a Hbx admin with read only permissions exists$/) do
  #Note: creates an enrollment for testing purposes in the UI
  p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: false)
  person = people['Hbx Admin']
  hbx_profile = FactoryGirl.create :hbx_profile
  user = FactoryGirl.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryGirl.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryGirl.create :hbx_enrollment, household:user.primary_family.active_household
end

Given(/^(.*)Employer for (.*) exists with a published health plan year$/) do |kind, named_person|
  person = people[named_person]
  organization = FactoryGirl.create :organization, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  employer_profile = FactoryGirl.create :employer_profile, organization: organization
  owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
  employee = FactoryGirl.create :census_employee, employer_profile: employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date]

  plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, fte_count: 2, aasm_state: :published
  benefit_group = FactoryGirl.create :benefit_group, plan_year: plan_year, is_congress: (kind == "Congressional " ? true : false)
  employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

Given(/^Employer for (.*) exists with a published plan year offering health and dental$/) do |named_person|
  person = people[named_person]
  organization = FactoryGirl.create :organization, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  employer_profile = FactoryGirl.create :employer_profile, organization: organization
  owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
  employee = FactoryGirl.create :census_employee, employer_profile: employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date]

  plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, fte_count: 2, aasm_state: :published
  benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: plan_year
  employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  Caches::PlanDetails.load_record_cache!
end

Given(/(.*) Employer for (.*) exists with active and renewing plan year/) do |kind, named_person|
  person = people[named_person]
  organization = FactoryGirl.create :organization, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  employer_profile = FactoryGirl.create :employer_profile, organization: organization, profile_source: (kind.downcase == 'conversion' ? kind.downcase : 'self_serve'), registered_on: TimeKeeper.date_of_record
  owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
  employee = FactoryGirl.create :census_employee, employer_profile: employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date]

  open_enrollment_start_on = TimeKeeper.date_of_record.end_of_month.next_day
  open_enrollment_end_on = open_enrollment_start_on + 12.days
  start_on = open_enrollment_start_on.next_month
  end_on = start_on.next_year.prev_day

  renewal_plan = FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01")
  plan = FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.prev_year.year, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id)

  plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on - 1.year, end_on: end_on - 1.year,
    open_enrollment_start_on: open_enrollment_start_on - 1.year, open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days,
    fte_count: 2, aasm_state: :published, is_conversion: (kind.downcase == 'conversion' ? true : false)

  benefit_group = FactoryGirl.create :benefit_group, plan_year: plan_year, reference_plan_id: plan.id
  employee.add_benefit_group_assignment benefit_group, benefit_group.start_on

  renewal_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on, fte_count: 2, aasm_state: :renewing_draft
  renewal_benefit_group = FactoryGirl.create :benefit_group, plan_year: renewal_plan_year, reference_plan_id: renewal_plan.id
  employee.add_renew_benefit_group_assignment renewal_benefit_group
  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
  FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

Given(/(.*) Employer for (.*) exists with active and expired plan year/) do |kind, named_person|
  person = people[named_person]
  organization = FactoryGirl.create :organization, :with_expired_and_active_plan_years, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  organization.employer_profile.update_attributes(profile_source: (kind.downcase == 'conversion' ? kind.downcase : 'self_serve'), registered_on: TimeKeeper.date_of_record)
  owner = FactoryGirl.create :census_employee, :owner, employer_profile: organization.employer_profile
  employee = FactoryGirl.create :census_employee, employer_profile: organization.employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date],
    hired_on: TimeKeeper.date_of_record - 15.months
  employee_role = FactoryGirl.create(:employee_role, employer_profile: organization.employer_profile)
  employee.update_attributes(employee_role_id: employee_role.id)
  expired_bg = organization.employer_profile.plan_years.where(aasm_state: "expired").first.benefit_groups.first
  employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group_id: expired_bg.id, start_on: expired_bg.start_on)

  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
  FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

Given(/(.*) Employer for (.*) exists with active and renewing enrolling plan year/) do |kind, named_person|
  person = people[named_person]
  organization = FactoryGirl.create :organization, :with_active_and_renewal_plan_years, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  organization.employer_profile.update_attributes(profile_source: (kind.downcase == 'conversion' ? kind.downcase : 'self_serve'), registered_on: TimeKeeper.date_of_record)
  owner = FactoryGirl.create :census_employee, :owner, employer_profile: organization.employer_profile
  employee = FactoryGirl.create :census_employee, employer_profile: organization.employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date],
    hired_on: TimeKeeper.date_of_record - 15.months
  employee_role = FactoryGirl.create(:employee_role, employer_profile: organization.employer_profile)
  employee.update_attributes(employee_role_id: employee_role.id)
  renewing_bg = organization.employer_profile.plan_years.where(aasm_state: "renewing_enrolling").first.benefit_groups.first
  employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group_id: renewing_bg.id, start_on: renewing_bg.start_on)

  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
  FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

When(/^.+ enters? office location for (.+)$/) do |location|
  location = eval(location) if location.class == String
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_1]', :with => location[:address1]
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_2]', :with => location[:address2]
  fill_in 'organization[office_locations_attributes][0][address_attributes][city]', :with => location[:city]

  find(:xpath, "//div[contains(@class, 'selectric')][p[contains(text(), 'SELECT STATE')]]").click
  find(:xpath, "//div[contains(@class, 'selectric-scroll')]/ul/li[contains(text(), '#{location[:state]}')]").click

  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', :with => location[:zip]
  fill_in 'organization[office_locations_attributes][0][phone_attributes][area_code]', :with => location[:phone_area_code]
  fill_in 'organization[office_locations_attributes][0][phone_attributes][number]', :with => location[:phone_number]
  fill_in 'organization[office_locations_attributes][0][phone_attributes][extension]', :with => location[:phone_extension]
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
  find('.interaction-click-control-confirm').click
end

When(/^(.*) logs on to the (.*)?/) do |named_person, portal|
  person = people[named_person]

  visit "/"
  portal_class = "interaction-click-control-#{portal.downcase.gsub(/ /, '-')}"
  portal_uri = find("a.#{portal_class}")["href"]

  visit "/users/sign_in"
  fill_in "user[login]", :with => person[:email]
  find('#user_login').set(person[:email])
  fill_in "user[password]", :with => person[:password]
  #TODO this fixes the random login fails b/c of empty params on email
  fill_in "user[login]", :with => person[:email] unless find(:xpath, '//*[@id="user_login"]').value == person[:email]
  find('.interaction-click-control-sign-in').click
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
  expect(page).to have_content("Welcome to #{Settings.site.short_name}. Your account has been created.")
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

Then(/^(?:.+) should be logged on as an unlinked employee$/) do
  screenshot("logged_in_welcome")
  @browser.a(href: /consumer\/employee\/search/).wait_until_present
  screenshot("logged_in_welcome")
  expect(@browser.a(href: /consumer.employee.search/).visible?).to be_truthy
end

When (/^(.*) logs? out$/) do |someone|
  click_link "Logout"
  visit "/"
end

When(/^.+ go(?:es)? to register as an employee$/) do
  find('.interaction-click-control-continue').click
end

Then(/^.+ should see the employee search page$/) do
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
  click_button 'Create account'

  person = people[named_person]

  fill_in "user[oim_id]", :with => person[:email]
  fill_in "user[password_confirmation]", :with => person[:password]
  fill_in "user[password]", :with => person[:password]
  screenshot("create_account")
  click_button "Create account"
end

When(/^.+ enters? the identifying info of (.*)$/) do |named_person|
  person = people[named_person]

  fill_in 'person[first_name]', :with => person[:first_name]
  fill_in 'person[last_name]', :with => person[:last_name]
  fill_in 'jq_datepicker_ignore_person[dob]', :with => person[:dob]
  fill_in 'person[ssn]', :with => person[:ssn]
  find(:xpath, '//label[@for="radio_male"]').click

  screenshot("information_entered")
  find('.interaction-click-control-continue').click
end

Then(/^.+ should not see the matched employee record form$/) do
  find('.fa-exclamation-triangle')
  expect(page).to_not have_css('.interaction-click-control-this-is-my-employer')
end

Then(/^Employee should see the matched employee record form$/) do
  expect(page).to have_content('Acme Inc.')
  screenshot("employer_search_results")
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
  employer_profile = EmployerProfile.find_by_fein(people[named_person][:fein])
  census_employee = CensusEmployee.where(:first_name => /#{people[named_person][:first_name]}/i, :last_name => /#{people[named_person][:last_name]}/i).first

  find('p', text: employer_profile.legal_name)
  find('.coverage_effective_date', text: census_employee.earliest_eligible_date.strftime("%m/%d/%Y"))
end

When(/^.+ completes? the matched employee form for (.*)$/) do |named_person|

  # Sometimes bombs due to overlapping modal
  # TODO: fix this bombing issue
  wait_for_ajax
  page.evaluate_script("window.location.reload()")
  person = people[named_person]
  screenshot("before modal")
  # find('.interaction-click-control-click-here').click
  screenshot("during modal")
  # find('.interaction-click-control-close').click
  screenshot("after modal")
  expect(page).to have_css('input.interaction-field-control-person-phones-attributes-0-full-phone-number')
  wait_for_ajax(3,2)

  #find("#person_addresses_attributes_0_address_1", :wait => 10).click
  # find("#person_addresses_attributes_0_address_1").trigger('click')
  # find("#person_addresses_attributes_0_address_2").trigger('click')
  # there is a flickering failure here due to over-lapping modals
  # find("#person_addresses_attributes_0_city").trigger('click')
  # find("#person_addresses_attributes_0_zip").trigger('click')
  find_by_id("person_phones_attributes_0_full_phone_number", wait: 10)
  fill_in "person[phones_attributes][0][full_phone_number]", :with => person[:home_phone]

  screenshot("personal_info_complete")
  wait_for_ajax
  fill_in "person[phones_attributes][0][full_phone_number]", :with => person[:home_phone] #because why not...
  expect(page).to have_field("HOME PHONE", with: "(#{person[:home_phone][0..2]}) #{person[:home_phone][3..5]}-#{person[:home_phone][6..9]}") if person[:home_phone].present?
  find("#btn-continue").click
end

Then(/^.+ should see the dependents page$/) do
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

Then(/^.+ should see ((?:(?!the).)+) dependents*$/) do |n|
  expect(page).to have_selector('li.dependent_list', :count => n.to_i)
end

When(/^.+ clicks? Add Member$/) do
  click_link "Add Member"
end

Then(/^.+ should see the new dependent form$/) do

  expect(page).to have_content('Confirm Member')
end

When(/^.+ enters? the dependent info of Sorens daughter$/) do
  fill_in 'dependent[first_name]', with: 'Cynthia'
  fill_in 'dependent[last_name]', with: 'White'
  fill_in 'jq_datepicker_ignore_dependent[dob]', with: '01/15/2011'
  find(:xpath, "//p[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, "//li[@data-index='3'][contains(., 'Child')]").click
  find(:xpath, "//label[@for='radio_female']").click
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
  expect(page).to have_css('form')
end

When(/^.+ clicks? health radio on the group selection page$/) do
  find(:xpath, '//label[@for="coverage_kind_dental"]').click
end

When(/^(?:(?!Employee).)+ clicks? continue on the group selection page$/) do
  find('#btn-continue').click
end

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
  click_button "Shop for Plans"
end

Then(/^.+ should see the list of plans$/) do
  expect(page).to have_link('Select')
  screenshot("plan_shopping")
end

And (/(.*) should see the plans from the (.*) plan year$/) do |named_person, plan_year_state|
  employer_profile = CensusEmployee.where(first_name: people[named_person][:first_name]).first.employee_role.employer_profile
  # cannot select a SEP date from expired plan year on 31st.
  if TimeKeeper.date_of_record.day != 31 || plan_year_state != "expired"
    expect(page).to have_content "#{employer_profile.plan_years.where(aasm_state: plan_year_state ).first.benefit_groups.first.reference_plan.name}"
  else
    expect(page).to have_content "#{employer_profile.plan_years.where(:aasm_state.ne => plan_year_state ).first.benefit_groups.first.reference_plan.name}"
  end
end

When(/^.+ selects? a plan on the plan shopping page$/) do
  click_link 'Select Plan'
end

Then(/^.+ should see the coverage summary page$/) do
  expect(page).to have_content('Confirm Your Plan Selection')
  screenshot("summary_page")
end

When(/^.+ clicks? on Confirm button on the coverage summary page$/) do
  find('.interaction-click-control-confirm').click
end

Then(/^.+ should see the receipt page$/) do
  expect(page).to have_content('Enrollment Submitted')
  screenshot("receipt_page")
  find('.interaction-click-control-continue').click
end

Then(/^.+ should see the "my account" page$/) do
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
  find('.interaction-click-control-add-new-employee', :wait => 10).click
end

When(/^(?:(?!General).)+ clicks? on the ((?:(?!General|Staff).)+) tab$/) do |tab_name|
  find(:xpath, "//li[contains(., '#{tab_name}')]", :wait => 10).click
  wait_for_ajax
end

And(/^clicks on the person in families tab$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  page.find('.families.dropdown-toggle.interaction-click-control-families').click
  find(:xpath, "//a[@href='/exchanges/hbx_profiles/family_index_dt']").click
  wait_for_ajax(10,2)
  family_member = page.find('a', :text => "#{user.person.full_name}")
  family_member.trigger('click')
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
    find(:xpath, '//*[@id="plan-details-modal-body"]/div[2]/button[2]').trigger('click')
  end
end

And(/I should not see any plan which premium is 0/) do
  page.all("h2.plan-premium").each do |premium|
    expect(premium).not_to have_content("$0.00")
  end
end

Then(/Employee should see the correct employee contribution on plan tile/) do
  enrollment = Person.all.first.primary_family.active_household.hbx_enrollments.where(:"aasm_state".ne => "shopping").first
  expect(page).to have_content "$#{enrollment.total_employee_cost.round(2)}"
end

Then(/Employee should see their current plan/) do
  expect(page).to have_content "YOUR CURRENT #{TimeKeeper.date_of_record.year} PLAN"
end

And(/Employee should have a ER sponsored enrollment/) do
  person = Person.all.first
  bg = Organization.all.first.employer_profile.plan_years[0].benefit_groups[0]
  enrollment = FactoryGirl.create :hbx_enrollment, household: person.primary_family.active_household, aasm_state: "coverage_selected",
                                    plan: Plan.all.first, benefit_group_id: bg.id
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(is_subscriber: true, applicant_id: person.primary_family.family_members[0].id,
                                        eligibility_date: TimeKeeper.date_of_record - 1.month, coverage_start_on: TimeKeeper.date_of_record)
  enrollment.save
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

Given(/^a Hbx admin with read and write permissions and employers$/) do
  p_staff=FactoryGirl.create :permission, :hbx_update_ssn
  person = people['Hbx AdminEnrollments']
  hbx_profile = FactoryGirl.create :hbx_profile
  user = FactoryGirl.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryGirl.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  org1 = FactoryGirl.create(:organization, legal_name: 'Acme Agency', hbx_id: "123456")
  employer_profile = FactoryGirl.create :employer_profile, organization: org1
  org2 = FactoryGirl.create(:organization, legal_name: 'Chase & Assoc', hbx_id: "67890")
  employer_profile = FactoryGirl.create :employer_profile, organization: org2
end

