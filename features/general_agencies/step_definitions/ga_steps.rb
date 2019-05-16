module GAWorld
  def general_agency(*traits)
    attributes = traits.extract_options!
    @general_agency ||= FactoryBot.create :general_agency, *traits, attributes.merge(:general_agency_traits => :with_staff)
  end
end
World(GAWorld)

Given /^a general agency agent visits the DCHBX$/ do
  visit '/'
end

When /^they click the 'New General Agency' button$/ do
  click_link 'General Agency Registration'
end

Then /^they should see the new general agency form$/ do
  expect(page).to have_content('General Agency Registration')
  screenshot("general_agency_registration")
end

When /^they complete the new general agency form and hit the 'Submit' button$/ do
  FactoryBot.create(:rating_area, zip_code: "01002", county_name: "Franklin", rating_area: Settings.aca.rating_areas.first)
  fill_in 'inputFirstname', with: Forgery(:name).first_name
  fill_in 'inputLastname', with: Forgery(:name).last_name
  fill_in 'inputDOB', with: (Time.now - rand(20..50).years).strftime('%m/%d/%Y')
  fill_in 'inputEmail', with: Forgery(:email).address
  fill_in 'inputNPN', with: '2222222222'
  select "Primary", from: "kindSelect"
  fill_in 'validationCustomLegalName', with: (company_name = Forgery(:name).company_name)
  fill_in 'validationCustomdba', with: company_name
  fill_in 'inputFein', with: '333333333'
  find(:xpath, "//*[@id='agency_organization_profile_attributes_market_kind']").click
  select "Small Business Marketplace ONLY", from: "agency_organization_profile_attributes_market_kind"
  fill_in 'inputAddress1', with: Forgery(:address).street_address
  fill_in 'agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_city', with: 'Washington'
  select Settings.aca.state_abbreviation, from: "inputState" #needs to change it to DC
  fill_in 'inputZip', with: '01002'
  wait_for_ajax
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][area_code]', with: '234'
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][number]', with: '9845945'
  find('#general-btn').click
end

Then /^they should see a confirmation message$/ do
  expect(page).to have_content('Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed.')
end

Then /^a pending approval status$/ do
  expect(::BenefitSponsors::Organizations::GeneralAgencyProfile.all.last.aasm_state).to eq('is_applicant')
end

When /^the HBX admin visits the general agency list$/ do
  login_as hbx_admin
  visit exchanges_hbx_profiles_root_path
  click_link 'General Agencies'
end

Then(/^Hbx Admin is on Broker Index and clicks General Agencies$/) do
  find('.interaction-click-control-general-agencies').click
end

Then /^they should see the pending general agency$/ do
  expect(page).to have_content(@general_agency_organization.legal_name)
  screenshot("general_agency_list")
end

When /^they click the link of general agency$/ do
  click_link @general_agency_organization.legal_name
end

Then /^they should see the home of general agency$/ do
  expect(page).to have_content("General Agency : #{@general_agency_organization.legal_name}")
  screenshot("general_agency_homepage")
end

When /^they visit the list of staff$/ do
  find('.interaction-click-control-staff').click
end

When /^they approve the general agency$/ do
  screenshot("general_agency_staff_edit_page")
  click_button 'Approve'
end

Then /^they should see updated status$/ do
  expect(find('.alert')).to have_content('Staff approved successfully.')
  screenshot("general_agency_staff_approved")
end

Then /^they should see an account creation form$/ do
  find('.create-account-btn', wait: 10)
  expect(page).to have_css('.create-account-btn')
  screenshot("general_agency_staff_register_by_invitation")
end

When /^they complete the account creation form and hit the 'Submit' button$/ do
  email_address = @general_agency_organization.general_agency_profile.general_agency_staff_roles.last.email_address
  fill_in "user[oim_id]", with: email_address
  fill_in "user[password]", with: "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", with: "aA1!aA1!aA1!"
  find('.create-account-btn', wait: 10).click
end

Then /^they should see a welcome message$/ do
  expect(page).to have_content("Welcome! You have signed up successfully")
  screenshot("general_agency_homepage_for_staff")
end

Then /^they see the General Agency homepage$/ do
  expect(page).to have_content(@general_agency_organization.legal_name)
end

Given /^a general agency, approved, confirmed, exists$/ do
  general_agency(legal_name: 'Rooxo')
  staff = general_agency.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
  staff.approve!
  email_address = general_agency.general_agency_profile.general_agency_staff_roles.last.email_address
  user = FactoryBot.create(:user, email: "ga1@dc.gov", password: "1qaz@WSX", password_confirmation: "1qaz@WSX")

  staff.person.user = user
  staff.person.save
  user.roles << "general_agency_staff" unless user.roles.include?("general_agency_staff")
  user.save
end

And /^a broker exists$/ do
  organization = FactoryBot.create(:organization, legal_name: 'Acarehouse Inc', dba: 'Acarehouse')
  broker_agency = FactoryBot.create(:broker_agency_profile, organization: organization)
  person = broker_agency.primary_broker_role.person
  person.emails.last.update(kind: 'work')
  user = FactoryBot.create(:user, email: "broker1@dc.gov", password: "1qaz@WSX", password_confirmation: "1qaz@WSX")
  person.user = user
  person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new({broker_agency_profile: broker_agency, aasm_state: 'active'})
  person.save
  user.roles << "broker" unless user.roles.include?("broker")
  if !user.roles.include?("broker_agency_staff")
    user.roles << "broker_agency_staff"
  end
  user.save
  broker_role = person.broker_role
  broker_role.approve
  broker_role.broker_agency_accept
  broker_role.broker_agency_profile_id = broker_agency.id
  broker_role.save
  broker_agency.approve!
end

And /^an employer exists for ga$/ do
  organization = FactoryBot.create(:organization, legal_name: 'EmployerA Inc', dba: 'EmployerA')
  employer_profile = FactoryBot.create :employer_profile, organization: organization
  user = FactoryBot.create :user, :with_family, :employer_staff, email: 'employer1@dc.gov', password: '1qaz@WSX', password_confirmation: '1qaz@WSX'
  FactoryBot.create :employer_staff_role, person: user.person, employer_profile_id: employer_profile.id
end

When /^the employer login in$/ do
  visit '/'
  portal_uri = find("a.interaction-click-control-employer-portal")["href"]
  click_link 'Employer Portal'
  find('.interaction-click-control-sign-in-existing-account', wait: 10).click

  fill_in "user[login]", with: "employer1@dc.gov"
  find('#user_login').set("employer1@dc.gov")
  find('#user_password').set("1qaz@WSX")
  fill_in "user[password]", with: "1qaz@WSX"
  fill_in "user[login]", :with => "employer1@dc.gov" unless find(:xpath, '//*[@id="user_login"]').value == "employer1@dc.gov"
  find('.interaction-click-control-sign-in').click
  visit portal_uri
end

Then /^the employer should see the home of employer$/ do
  expect(page).to have_content("I'm an Employer")
end

When /^the employer click the link of brokers$/ do
  find('.interaction-click-control-brokers').click
end

Then /^the employer should see the broker agency$/ do
  expect(page).to have_content('Acarehouse')
end

Then /^the employer should see Acarehouse broker active for the employer$/ do
  expect(page).to have_content('Acarehouse')
  expect(page).to have_content(/active broker/i)
end

When /^the broker login in$/ do
  visit '/'
  click_link 'Broker Agency Portal'
  find('.interaction-click-control-sign-in-existing-account', wait: 10).click

  fill_in "user[login]", with: "broker1@dc.gov"
  find('#user_login').set("broker1@dc.gov")
  fill_in "user[password]", with: "1qaz@WSX"
  fill_in "user[login]", :with => "broker1@dc.gov" unless find(:xpath, '//*[@id="user_login"]').value == "broker1@dc.gov"
  find('.interaction-click-control-sign-in').click
end

Then /^the broker should see the home of broker$/ do
  expect(page).to have_content('Broker Agency : Acarehouse')
end

When /^the broker visits their Employers page$/ do
  find('.interaction-click-control-employers').click
end

And /^selects the general agency from dropdown for the employer$/ do
  expect(page).to have_content('EmployerA')
  find(:xpath, "//*[@id='datatable_filter_bulk_actions']").click
  find(:xpath, "//p[@class='label'][contains(., 'Select General Agency')]").click
  find(:xpath, "//li[contains(., 'Rooxo')]").click
  find("#assign_general_agency").click
end

Then /^the employer is assigned to general agency$/ do
  expect(page).to have_content('Employers')
  expect(page).to have_content('EmployerA Inc')
  expect(page).to have_content('General Agencies')
  expect(page).to have_content('Rooxo')
end

Then /^the employer is assigned to GA2$/ do
  expect(page).to have_content('Employers')
  expect(page).to have_content('EmployerA Inc')
  expect(page).to have_content('General Agencies')
  expect(page).to have_content('Zooxy')
end

When /^the broker click the link of clear assign$/ do
  click_link 'clear assign'
end

Then /^the employer will not be assigned that general agency$/ do
  expect(page).to have_content('Employers')
  expect(page).to have_content('EmployerA Inc')
  expect(page).to have_content('General Agencies')
  expect(page).not_to have_content('Rooxo')
end

When /^the broker visits their general agencies page$/ do
  find(".interaction-click-control-general-agencies").click
end

Then /^the broker should not see the link General Agencies/ do
  expect(page).should_not have_link('General Agencies')
end

When /^the broker set default ga$/ do
  first(:xpath, "//a[contains(., 'Select Default GA')]").click
end

Then /^the broker should see default ga msg$/ do
  expect(page).to have_content("this is your default GA, to change your default GA click 'Select Default GA' under your desired agency.")
end

Then /^the broker should see no default ga msg$/ do
  expect(page).to have_content("You do not have default GA, to select your default GA click 'Select Default GA' under your desired agency.")
end

Given /^call change default ga subscriber for ga1$/ do
  broker = User.find_by(email: "broker1@dc.gov")
  hbx_id = broker.person.hbx_id
  Subscribers::DefaultGaChanged.new.call(nil, nil, nil, nil, {broker_id: hbx_id})
end

Given /^call change default ga subscriber for ga1 with pre default ga id$/ do
  broker = User.find_by(email: "broker1@dc.gov")
  hbx_id = broker.person.hbx_id
  pre_ga_id = Organization.find_by(legal_name: 'Rooxo').try(:general_agency_profile).try(:id).try(:to_s)
  Subscribers::DefaultGaChanged.new.call(nil, nil, nil, nil, {broker_id: hbx_id, pre_default_ga_id: pre_ga_id})
end

When /^the ga login in$/ do
  email_address = "ga1@dc.gov"
  visit '/'
  click_link 'General Agency Portal'
  find('.interaction-click-control-sign-in-existing-account').click

  fill_in "user[login]", with: email_address
  find('#user_login').set(email_address)
  fill_in "user[password]", with: "1qaz@WSX"
  fill_in "user[login]", :with => email_address unless find(:xpath, '//*[@id="user_login"]').value == email_address
  find('.interaction-click-control-sign-in').click
end

Then /^the ga should see the home of ga$/ do
  expect(page).to have_content('General Agency : Rooxo')
end

When /^the ga visits their Employers page$/ do
  find('.interaction-click-control-employers').click
end

Then /^the ga should see the employer$/ do
  expect(page).to have_content('EmployerA Inc')
end

When /^the ga click the name of employer$/ do
  click_link "EmployerA Inc"
end

Then /^the ga should see the home of employer$/ do
  expect(page).to have_content('My Health Benefits Program')
end

Then /^the ga should see the broker$/ do
  expect(page).to have_content('Acarehouse')
  expect(page).to have_selector('.disabled', text: 'Change Broker')
  expect(page).to have_selector('.disabled', text: 'Browse Brokers')
end

When /^the ga click the back link$/ do
  click_link "I'm a General Agency"
end

Given /^another general agency-ga2, approved, confirmed, exists$/ do
  general_agency = FactoryBot.create :general_agency, legal_name: 'Zooxy', general_agency_traits: :with_staff
  staff = general_agency.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
  staff.approve!
  email_address = general_agency.general_agency_profile.general_agency_staff_roles.last.email_address
  user = FactoryBot.create(:user, email: "ga2@dc.gov", password: "1qaz@WSX", password_confirmation: "1qaz@WSX")

  staff.person.user = user
  staff.person.save
  user.roles << "general_agency_staff" unless user.roles.include?("general_agency_staff")
  user.save
end

And /^selects the GA2 from dropdown for the employer$/ do
  expect(page).to have_content('EmployerA')
  find(:xpath, "//*[@id='datatable_filter_bulk_actions']").click
  find(:xpath, "//p[@class='label'][contains(., 'Select General Agency')]").click
  find(:xpath, "//li[contains(., 'Zooxy')]").click
  find("#assign_general_agency").click
end

Then /^the employer has assigned to GA2$/ do
  expect(page).to have_content('Employers')
  expect(page).to have_content('EmployerA Inc')
  expect(page).to have_content('General Agencies')
  expect(page).to have_content('Zooxy')
end

Then /^the broker should see the Clear Default GA in the list of general agencies$/ do
  expect(page).to have_content('General Agencies')
  expect(page).to have_content('Clear Default GA')
  #expect(page).to have_content('Zooxy')
  #expect(page).to have_content('Rooxo')
end

When /^the ga2 login in$/ do
  email_address = "ga2@dc.gov"
  visit '/'
  click_link 'General Agency Portal'
  find('.interaction-click-control-sign-in-existing-account').click

  fill_in "user[login]", with: email_address
  find('#user_login').set(email_address)
  fill_in "user[password]", with: "1qaz@WSX"
  fill_in "user[login]", :with => email_address unless find(:xpath, '//*[@id="user_login"]').value == email_address
  find('.interaction-click-control-sign-in').click
end

Then /^the ga2 should see the home of ga$/ do
  expect(page).to have_content('General Agency : Zooxy')
end

When /^the ga2 visits their Employers page$/ do
  find('.interaction-click-control-employers').click
end

Then /^the ga2 should not see the employer$/ do
  expect(page).not_to have_content('EmployerA Inc')
end

When /^the broker click the link of clear default ga$/ do
  click_link "Clear Default GA"
end

Then(/^he should be able to see the Assign link under his profile$/) do
 expect(page).to have_selector('#assign-tab')
end

Then(/^he should not be able to see the Assign link under his profile$/) do
expect(page).not_to have_selector('#assign-tab')
end

When(/^the ga clicks on EDIT GENERAL AGENCY button\/link$/) do
  click_link "Edit General Agency"
end

Then(/^the ga should see ga profile form to update informaton$/) do
  expect(page).to have_content('General Agency / TPA Modification')
end

When(/^the ga enters personal information or general agency information or office location$/) do
  fill_in "organization[npn]", with: "3457684567"
  fill_in "organization[legal_name]", with: "Sample General LLc"
end

And(/^the ga clicks update general agency$/) do
  click_button "Update General Agency"
end

Then(/^the ga should see successful message\.$/) do
  expect(page).to have_content('Successfully Update General Agency Profile')
end

Then(/^the ga should see updated informaton on page$/) do
  expect(page).to have_content("Sample General LLc")
end
