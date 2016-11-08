module GAWorld
  def general_agency(*traits)
    attributes = traits.extract_options!
    @general_agency ||= FactoryGirl.create :general_agency, *traits, attributes.merge(:general_agency_traits => :with_staff)
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
  expect(page).to have_content('General Agency / TPA Registration')
  screenshot("general_agency_registration")
end

When /^they complete the new general agency form and hit the 'Submit' button$/ do
  fill_in 'organization[first_name]', with: Forgery(:name).first_name
  fill_in 'organization[last_name]', with: Forgery(:name).last_name
  fill_in 'jq_datepicker_ignore_organization[dob]', with: (Time.now - rand(20..50).years).strftime('%m/%d/%Y')
  find('.interaction-field-control-organization-email').click
  fill_in 'organization[email]', with: Forgery(:email).address
  fill_in 'organization[npn]', with: '2222222222'
  fill_in 'organization[legal_name]', with: (company_name = Forgery(:name).company_name)
  fill_in 'organization[dba]', with: company_name
  fill_in 'organization[fein]', with: '333333333'
  find(:xpath, "//p[contains(., 'Select Practice Area')]").click
  find('.selectric-items').find('.interaction-choice-control-organization-market-kind-1').click
  find('.multiselect').click
  find(:xpath, "//li[contains(., 'English')]").click
  find('.multiselect').trigger('click')
  find('input.interaction-field-control-organization-legal-name').click
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_1]', with: Forgery(:address).street_address
  fill_in 'organization[office_locations_attributes][0][address_attributes][city]', with: 'Washington'

  find(:xpath, "//p[contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[contains(., 'DC')]").click

  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', with: '20001'

  fill_in 'organization[office_locations_attributes][0][phone_attributes][area_code]', with: Forgery(:address).phone.match(/\((\d\d\d)\)/)[1]
  fill_in 'organization[office_locations_attributes][0][phone_attributes][number]', with: Forgery(:address).phone.match(/\)(.*)$/)[1]

  find('.interaction-click-control-create-general-agency').click
end

Then /^they should see a confirmation message$/ do
  expect(page).to have_content('Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed.')
end

Then /^a pending approval status$/ do
  expect(GeneralAgencyProfile.last.aasm_state).to eq('is_applicant')
end

And /^a general agency, pending approval, exists$/ do
  general_agency
  staff = general_agency.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
end

When /^the HBX admin visits the general agency list$/ do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  click_link 'General Agencies'
end

Then /^they should see the pending general agency$/ do
  expect(page).to have_content(general_agency.legal_name)
  screenshot("general_agency_list")
end

When /^they click the link of general agency$/ do
  click_link general_agency.legal_name
end

Then /^they should see the home of general agency$/ do
  expect(page).to have_content("General Agency : #{general_agency.legal_name}")
  screenshot("general_agency_homepage")
end

When /^they visit the list of staff$/ do
  find('.interaction-click-control-staff').click
end

Then /^they should see the name of staff$/ do
  full_name = general_agency.general_agency_profile.general_agency_staff_roles.last.person.full_name
  expect(page).to have_content("General Agency Staff")
  expect(page).to have_content(general_agency.legal_name)
  expect(page).to have_content(full_name)
  screenshot("general_agency_staff_list")

  click_link full_name
end

When /^they approve the general agency$/ do
  click_link general_agency.general_agency_profile.general_agency_staff_roles.last.person.full_name
  screenshot("general_agency_staff_edit_page")
  click_button 'Approve'
end

Then /^they should see updated status$/ do
  expect(find('.alert')).to have_content('Staff approved successfully.')
  screenshot("general_agency_staff_approved")
end

Then /^the general agency should receive an email$/ do
  staff = general_agency.general_agency_profile.general_agency_staff_roles.last
  open_email(staff.email_address)
end

Given /^a general agency, approved, awaiting account creation, exists$/ do
  general_agency
  staff = general_agency.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
  staff.approve!
end

When /^the HBX admin visits the link received in the approval email$/ do
  staff = general_agency.general_agency_profile.general_agency_staff_roles.last
  email_address = staff.email_address

  open_email(email_address)
  expect(current_email.to).to eq([email_address])

  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/http\:\/\/127\.0\.0\.1\:3000/, '')
  visit(invitation_link)
end

Then /^they should see an account creation form$/ do
  expect(page).to have_css('.interaction-click-control-create-account')
  screenshot("general_agency_staff_register_by_invitation")
end

When /^they complete the account creation form and hit the 'Submit' button$/ do
  email_address = general_agency.general_agency_profile.general_agency_staff_roles.last.email_address
  fill_in "user[oim_id]", with: email_address
  fill_in "user[password]", with: "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", with: "aA1!aA1!aA1!"
  click_button 'Create account'
end

Then /^they should see a welcome message$/ do
  expect(page).to have_content("Welcome to #{Settings.site.short_name}. Your account has been created.")
  screenshot("general_agency_homepage_for_staff")
end

Then /^they see the General Agency homepage$/ do
  expect(page).to have_content(general_agency.legal_name)
end

Given /^a general agency, approved, confirmed, exists$/ do
  general_agency(legal_name: 'Rooxo')
  staff = general_agency.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
  staff.approve!
  email_address = general_agency.general_agency_profile.general_agency_staff_roles.last.email_address
  user = FactoryGirl.create(:user, email: "ga1@dc.gov", password: "1qaz@WSX", password_confirmation: "1qaz@WSX")

  staff.person.user = user
  staff.person.save
  user.roles << "general_agency_staff" unless user.roles.include?("general_agency_staff")
  user.save
end

And /^a broker exists$/ do
  organization = FactoryGirl.create(:organization, legal_name: 'Acarehouse Inc', dba: 'Acarehouse')
  broker_agency = FactoryGirl.create(:broker_agency_profile, organization: organization)
  person = broker_agency.primary_broker_role.person
  person.emails.last.update(kind: 'work')
  user = FactoryGirl.create(:user, email: "broker1@dc.gov", password: "1qaz@WSX", password_confirmation: "1qaz@WSX")
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
  organization = FactoryGirl.create(:organization, legal_name: 'EmployerA Inc', dba: 'EmployerA')
  employer_profile = FactoryGirl.create :employer_profile, organization: organization
  user = FactoryGirl.create :user, :with_family, :employer_staff, email: 'employer1@dc.gov', password: '1qaz@WSX', password_confirmation: '1qaz@WSX'
  FactoryGirl.create :employer_staff_role, person: user.person, employer_profile_id: employer_profile.id
end

When /^the employer login in$/ do
  visit '/'
  portal_uri = find("a.interaction-click-control-employer-portal")["href"]
  click_link 'Employer Portal'
  find('.interaction-click-control-sign-in-existing-account').click

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
  find("input#employer_ids_").click
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

When /^the broker set default ga$/ do
  first(:xpath, "//a[contains(., 'Select Default GA')]").click
end

Then /^the broker should see default ga msg$/ do
  expect(page).to have_content("this is your default GA, to change your default GA click \"Select Default GA\" under your desired agency.")
end

Then /^the broker should see no default ga msg$/ do
  expect(page).to have_content("You do not have default GA, to select your default GA click \"Select Default GA\" under your desired agency.")
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
  expect(page).to have_selector('.disabled', text: 'ROWSE BROKERS')
end

When /^the ga click the back link$/ do
  click_link "I'm a General Agency"
end

Given /^another general agency-ga2, approved, confirmed, exists$/ do
  general_agency = FactoryGirl.create :general_agency, legal_name: 'Zooxy', general_agency_traits: :with_staff
  staff = general_agency.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
  staff.approve!
  email_address = general_agency.general_agency_profile.general_agency_staff_roles.last.email_address
  user = FactoryGirl.create(:user, email: "ga2@dc.gov", password: "1qaz@WSX", password_confirmation: "1qaz@WSX")

  staff.person.user = user
  staff.person.save
  user.roles << "general_agency_staff" unless user.roles.include?("general_agency_staff")
  user.save
end

And /^selects the GA2 from dropdown for the employer$/ do
  expect(page).to have_content('EmployerA')
  find("input#employer_ids_").click
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
