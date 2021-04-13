# frozen_string_literal: true

Then(/Employee (.*) should click Manage Family/) do |_named_person|
  find('a.interaction-click-control-manage-family').click
end

Then(/Employee (.*) should click the Personal Tab/) do |_named_person|
  find('a.interaction-click-control-personal').click
end

Then(/Employee (.*) should click Change my Password/) do |_named_person|
  if aca_security_questions
    wait_for_ajax
    page.execute_script("document.querySelector('#change_password_link').click()")
  end
end

Then(/Employee (.*) should click Update my security challenge responses/) do |_named_person|
  if aca_security_questions
    wait_for_ajax
    page.execute_script("document.querySelector('#update_security_responses_link').click()")
  end
end

Then(/they attempt to submit a new password/) do
  fill_in 'user[password]', with: 'thisisnotthepassword'
  fill_in 'user[new_password]', with: 'NewPass!@#$1234'
  fill_in 'user[password_confirmation]', with: 'NewPass!@#$1234'
  page.find_button('Change my password').click
  sleep 1
end

And(/they should see a successful password message/) do
  expect(page).to have_text 'Password successfully changed'
end

And(/person filled all the fields in the employer information form/) do
  fill_in Registration.email, with: 'chessmenwidgets@gmail.com'
  fill_in Registration.area_code_personal_information, with: '444'
  fill_in Registration.number_personal_information, with: '9894399'
  fill_in Registration.legal_name, with: 'Chessmen Widgets'
  fill_in Registration.dba, with: ''
  fill_in Registration.fein, with: '989888399'
  select "Tax Exempt Organization", from: Registration.kind
  select "Primary", from: Registration.kind_office_location_dropdown
  fill_in Registration.address, with: '123 H St'
  fill_in Registration.address_two, with: ''
  fill_in Registration.city, with: 'Washington'
  select "DC", from: Registration.state_dropdown
  fill_in Registration.zip, with: '20024'
  fill_in Registration.area_code_office_location, with: '344'
  fill_in Registration.number_office_location, with: '3434344'
  select "Only Electronic communications", from: Registration.contact_method_dropdown
end

And(/person clicks on add portal/) do
  page.execute_script("document.querySelector('#employer_registration_form').click()")
end

And(/person clicks on add role on pop up/) do
  page.execute_script("document.querySelector('.add-role').click()")
end

Then(/person should see a modal confirmation popup/) do
  page.execute_script("document.querySelector('#employer_registration_form').click()")
end

Then(/person should see employer home page/) do
  expect(page).to have_content('My Health Benefits Program')
end

Then(/person searches for (.*) with name (.*)/) do |role, legal_name|
  case role
  when 'employer'
    fill_in ManageAccount::Portals::EmployerStaff.employer_search, with: legal_name
  when 'broker'
    fill_in ManageAccount::Portals::BrokerStaff.broker_search, with: legal_name
  when 'ga'
    fill_in ManageAccount::Portals::GeneralAgencyStaff.general_agency_search, with: legal_name
  end
  click_button 'Search'
end

Then(/person searches for (.*) broker/) do |legal_name|
  fill_in ManageAccount::Portals::EmployerStaff.employer_search, with: legal_name
  click_button 'Search'
end

Then(/person clicks on select this (.*)/) do |type|
  case type
  when 'employer'
    click_link 'SELECT THIS EMPLOYER'
  when 'broker'
    click_link 'SELECT THIS BROKER'
  when 'ga'
    click_link 'SELECT THIS GENERAL AGENCY'
  end
end

Then(/person clicks on submit (.*) application/) do |app_type|
  case app_type
  when 'employer'
    page.execute_script("document.querySelector('#employer-staff-btn').click()")
  when 'broker'
    page.execute_script("document.querySelector('#broker-staff-btn').click()")
  when 'ga'
    page.execute_script("document.querySelector('#general-agency-staff-btn').click()")
  end
end

Then(/person should see (.*) success message/) do |role|
  case role
  when 'employer'
    expect(page).to have_content ManageAccount::Portals::EmployerStaff.success_message
  when 'broker'
    expect(page).to have_content ManageAccount::Portals::BrokerStaff.success_message
  when 'ga'
    expect(page).to have_content ManageAccount::Portals::GeneralAgencyStaff.success_message
  end
end

And(/person should see (.*)'s details under pending portals/) do |legal_name|
  expect(page).to have_text legal_name
end

And(/person should be able to click add (.*) portal/) do |role|
  case role
  when 'employer'
    visit "/benefit_sponsors/profiles/registrations/new_employer_profile_form?person_id=#{@person.id}&profile_type=benefit_sponsor"
  else
    visit "/benefit_sponsors/profiles/employers/employer_staff_roles/new_staff_member?id=#{@person.id}"
  end
end

Then(/person should be able to visit add new portal/) do
  click_link 'Add New Portal'
end

Then(/person should be able to visit add new employer poc portal/) do
  visit benefit_sponsors.new_staff_member_profiles_employers_employer_staff_roles_path(id: @person.id)
end

Then(/person should be able to visit add new broker poc portal/) do
  visit benefit_sponsors.new_staff_member_profiles_broker_agencies_broker_agency_staff_roles_path(id: @person.id)
end

Then(/person should be able to visit add new general agency poc portal/) do
  visit benefit_sponsors.new_staff_member_profiles_general_agencies_general_agency_staff_roles_path(id: @person.id)
end

Then(/person should be able to see (.*) page/) do |text|
  expect(page).to have_content text
end

Then(/person (.*) see add new portal link/) do |add_new_portal_visible|
  if add_new_portal_visible == 'should'
    expect(page).to have_link 'Add New Portal'
  else
    expect(page).not_to have_link 'Add New Portal'
  end
end

Then(/person should see available portals/) do
  expect(page).to have_content('Available Portals')
end

And(/they should see a password error message/) do
  expect(page).to have_text 'That password does not match the one we have stored'
end

Then(/I should see a security response success message/) do
  expect(page).to have_text 'Security responses successfully updated'
end

And(/that a person with (.*) exists in EA/) do |role|
  Person.create_indexes
  user = FactoryBot.create(:user)
  case role
  when 'Consumer'
    FactoryBot.create(:person, :with_consumer_role, :with_family, first_name: "Consumer", last_name: "role", user: user)
  when 'Resident'
    FactoryBot.create(:person, :with_resident_role, :with_family, first_name: "Resident", last_name: "role", user: user)
  when 'Employee'
    step "a matched Employee exists with only employee role"
  when 'Employer Staff'
    create_employer_staff(role, "Test", user)
  when 'Broker Staff'
    create_broker_staff(role, "Test", user)
  when 'GA Staff'
    create_ga_staff(role, "Test", user)
  end
end

Then(/person should be able to visit add new employee portal/) do
  find('#employee-portal').click
end

Then(/person should be able to visit add new consumer portal/) do
  find('#consumer-portal').click
end

And(/person with (.*) signs in and visits manage account/) do |role|
  @person ||= Person.where(first_name: role.split(/\s/)[0]).first
  user = @person.user
  login_as user
  visit "/people/#{@person.id}/manage_account"
end

And(/person clicks on personal info section/) do
  click_link 'Personal Info'
end

And(/person clicks on my portals tab/) do
  click_link 'My Portals'
end

Given(/(.*) employer has (.*) as employer staff/) do |legal_name, named_person|
  employer_profile = employer_profile(legal_name)
  employer_staff_role = FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)
  @person = FactoryBot.create(:person, first_name: people[named_person][:first_name], last_name: people[named_person][:last_name], dob: people[named_person][:dob_date])
  @person.employer_staff_roles << employer_staff_role
  @person.save
  @staff_role ||= FactoryBot.create(:user, :person => @person, email: people[named_person][:email])
end

Then(/person should see their indentifying information/) do
  expect(page).to have_content 'Personal Information'
  first_name = @person.first_name
  if first_name == 'GA'
    first_name = 'General Agency'
  else
    first_name
  end
  expect(page).to have_text first_name
end

Then(/person enters ssn under personal information for (.*)/) do |named_person|
  fill_in Insured::Employee::PersonalInformation.ssn, with: number_to_ssn(@census_employee[named_person].ssn)
  find('.interaction-click-control-continue').click
end

Then(/person clicks on Add Role/) do
  click_link 'Add Role'
end

And(/person clicks on add new portal link/) do
  visit "people/#{@person.id}/available_accounts"
end

Then(/person should see add new employer poc portal link/) do
  expect(page).to have_content('Employer POC')
end

Then(/person should see add new broker poc portal link/) do
  expect(page).to have_content('Broker POC')
end

Then(/person should see add new general agency poc portal link/) do
  expect(page).to have_content('General Agency POC')
end

Then(/person should see their (.*) information under active portals/) do |role|
  display_name = @person.general_agency_staff_roles.present? ? @person.general_agency_staff_roles.first.general_agency_profile.legal_name : @person.full_name
  find(class: 'portal-label', text: display_name).visible?
  expect(page).to have_content(role.split(/\s/)[0])
end

Then(/^person should see newly created (.*) portal link$/) do |created_role|
  expect(page).to have_content(created_role.split(/\s/)[0])
end

Then(/person should see his (.*) information/) do |role|
  expect(find_field(ManageAccount::PersonalInformation.first_name).value).to have_content role.split(/\s/)[0]
  expect(page).to have_css(ManageAccount::PersonalInformation.personal_information_form)
end

And(/person edits his information/) do
  fill_in ManageAccount::PersonalInformation.first_name, with: "Update"
  fill_in ManageAccount::PersonalInformation.last_name, with: "Person"
  select "Male", from: ManageAccount::PersonalInformation.gender
end

When(/person clicks update/) do
  page.execute_script("document.querySelector('#save-person').click()")
end

And(/person should see the successful message/) do
  expect(page).to have_content(ManageAccount::PersonalInformation.success_message)
end
