Given /(\w+) is a person$/ do |name|
  SicCode.where(sic_code: '0111').first || FactoryBot.create(:sic_code, sic_code: "0111")

  person = FactoryBot.create(:person, first_name: name)
  @pswd = 'aA1!aA1!aA1!'
  email = Forgery('email').address
  user = User.create(email: email, password: @pswd, password_confirmation: @pswd, person: person, oim_id: email)
end

Given /(\w+) is census employee to (.*?)$/ do |name, legal_name|
  org = @organization[legal_name]
  @cesnus_employees = FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: org.benefit_sponsorships.first, employer_profile: org.employer_profile)
end

Given /(\w+) has already provided security question responses/ do |name|
  security_questions = []
  3.times do
    security_questions << FactoryBot.create(:security_question)
  end
  User.all.each do |u|
    next if u.security_question_responses.count == 3
    security_questions.each do |q|
      u.security_question_responses << FactoryBot.build(:security_question_response, security_question_id: q.id, question_answer: 'answer')
    end
    u.save!
  end
end

And /(\w+) also has a duplicate person with different DOB/ do |name|
  person = Person.where(first_name: name).first
  FactoryBot.create(:person, first_name: person.first_name,
            last_name: person.last_name, dob: '06/06/1976')
end
Given /(\w+) is a person who has not logged on$/ do |name|
  person = FactoryBot.create(:person, first_name: name)
end

Then  /(\w+) signs in to portal/ do |name|
  if page.has_link? 'Sign In'
    find('.interaction-click-control-sign-in-existing-account').click
  end
  person = Person.where(first_name: name).first
  fill_in "user[login]", :with => person.user.oim_id
  find('#user_login').set(person.user.email)
  fill_in "user[password]", :with => @pswd
  #TODO this fixes the random login fails b/c of empty params on email
  fill_in "user[login]", :with => person.user.email unless find(:xpath, '//*[@id="user_login"]').value == person.user.email
  find('.interaction-click-control-sign-in').click
end

Given /(\w+) is a user with no person who goes to the Employer Portal/ do |name|
  SicCode.where(sic_code: '0111').first || FactoryBot.create(:sic_code, sic_code: "0111")

  email = Forgery('email').address
  visit '/'
  portal_class = '.interaction-click-control-employer-portal'
  find(portal_class).click
  find('.interaction-click-control-create-account').click
  @pswd = 'aA1!aA1!aA1!'
  fill_in "user[oim_id]", :with => email
  fill_in "user[password]", :with => @pswd
  fill_in "user[password_confirmation]", :with => @pswd

  find(:xpath, '//label[@for="user_email_or_username"]').set(email)
  #TODO this fixes the random login fails b/c of empty params on email
  fill_in "user[oim_id]", :with => email unless find(:xpath, '//label[@for="user_email_or_username"]').value == email
  find('.interaction-click-control-create-account').click
end

Given /(\w+) enters first, last, dob and contact info/ do |name|
  fill_in 'organization[first_name]', :with => name
  fill_in 'organization[last_name]', with: Forgery('name').last_name
  fill_in 'jq_datepicker_ignore_organization[dob]', with: '03/03/1993'
  #fill_in('organization[first_name]').click
  fill_in 'organization[email]', with: Forgery('internet').email_address
  fill_in 'organization[area_code]', with: 202
  fill_in 'organization[number]', with: '555-1212'
end

Given /(\w+) enters info matching the employer staff role/ do |name|

  person = Person.where(first_name: name).first
  fill_in 'organization[first_name]', with: person.first_name
  fill_in 'organization[last_name]', with: person.last_name
  fill_in 'jq_datepicker_ignore_organization[dob]', with: person.dob
  fill_in 'organization[email]', with: Forgery('internet').email_address
  fill_in 'organization[area_code]', with: 202
  fill_in 'organization[number]', with: '555-1212'
end

Given /(\w+) matches with different DOB from employer staff role/ do |name|
  person = Person.where(first_name: name).first
  fill_in 'organization[first_name]', with:  person.first_name
  fill_in 'organization[last_name]', with: person.last_name
  fill_in 'jq_datepicker_ignore_organization[dob]', with: '03/03/1993'
  fill_in 'organization[email]', with: Forgery('internet').email_address
  fill_in 'organization[area_code]', with: 202
  fill_in 'organization[number]', with: '555-1212'
end

Then(/(\w+) is the staff person for an employer$/) do |name|
  person = Person.where(first_name: name).first
  employer_staff_role = FactoryBot.create(:employer_staff_role, person: person, benefit_sponsor_employer_profile_id: employer_profile.id)
end

Given(/^Sarah is the staff person for an organization with employer profile and broker agency profile$/) do
  person = Person.where(first_name: "Sarah").first
  organization = FactoryBot.create(:organization)
  employer_profile = FactoryBot.create(:employer_profile, organization: organization)
  employer_staff_role = FactoryBot.create(:employer_staff_role, person: person, employer_profile_id: employer_profile.id)
  broker_agency_profile = FactoryBot.create(:broker_agency_profile, organization: organization)
end

Then(/he should have an option to select paper or electronic notice option/) do
  expect(page).to have_content("Please indicate preferred method to receive notices (optional)")
  find('.selectric-interaction-choice-control-organization-contact-method').click
  expect(page).to have_content(/Only Electronic communications/i)
  expect(page).to have_content(/Paper and Electronic communications/i)
end

Then(/(\w+) is the staff person for an existing employer$/) do |name|
  person = Person.where(first_name: name).first
  employer_staff_role = FactoryBot.create(:employer_staff_role, person: person, employer_profile_id: @employer_profile.id)
end

Then(/(\w+) is applicant staff person for an existing employer$/) do |name|
  person = Person.where(first_name: name).first
  employer_staff_role = FactoryBot.create(:employer_staff_role, person: person, employer_profile_id: @employer_profile.id, aasm_state: 'is_applicant')
end

When(/(\w+) accesses the Employer Portal/) do |name|
  person = Person.where(first_name: name).first
  visit '/'
  portal_class = 'interaction-click-control-employer-portal'
  find("a.#{portal_class}").click

  step "#{name} signs in to portal"
end

Then /(\w+) decides to Update Business information/ do |person|
  FactoryBot.create(:sic_code, sic_code: "0111")
  find('.interaction-click-control-update-business-info', :wait => 10).click
  wait_for_ajax(10,2)
  screenshot('update_business_info')
end

And /(.*?) fills in all mandatory fields and clicks on save$/ do |legal_name|
  find(:xpath, "//*[@id='staff_first_name']").set "john"
  find(:xpath, "//*[@id='staff_last_name']").set "snow"
  find(:xpath, "//*[@id='staff_dob']").set "09/11/1990"
  find(:xpath, "//*[@id='new_staff']/button").click
end

And /Employer enters (.*?) details and clicks on save$/ do |new_staff|
  person = Person.where(first_name: new_staff).first

  find(:xpath, "//*[@id='staff_first_name']").set person.first_name
  find(:xpath, "//*[@id='staff_last_name']").set person.last_name
  find(:xpath, "//*[@id='staff_dob']").set person.dob
  find(:xpath, "//*[@id='new_staff']/button").click
end

Then /employer should see a error flash message/ do
  expect(page).to have_content /Role was not added because Person does not exist on the HBX Exchange/
end

Then /employer should see a success flash message/ do
  expect(page).to have_content /Role added sucessfully/
end

Given /(\w+) adds an EmployerStaffRole to (\w+)/ do |staff, new_staff|
  person = Person.where(first_name: new_staff).first

  click_link 'Add Employer Staff Role'
  fill_in 'staff_first_name', with: person.first_name
  fill_in 'staff_last_name', with: person.last_name
  fill_in  'staff_dob', with: person.dob
  screenshot('add_existing_person_as_staff')
  find_all('.btn-primary')[0].click
  step 'Point of Contact count is 2'
end

Then /Point of Contact count is (\d+)/ do |count|
  sleep(10)
  expect(page.all('tr').count - 1).to eq(count.to_i)
end

Then /(\w+) cannot remove EmployerStaffRole from John/ do |legal_name|
  staff = Person.where(first_name: legal_name).first
  accept_alert do
    find(:xpath, '//*[@id="edit_agency"]/div/div/div[1]/table/tbody/tr/td[6]/a').click
  end
end

When /(\w+) removes EmployerStaffRole from Sarah/ do |staff2|
  staff = Person.where(first_name: staff2).first
  accept_alert do
    find(:xpath, '//*[@id="edit_agency"]/div/div/div[1]/table/tbody/tr[2]/td[6]/a/i').click
  end
end

Then /(\w+) removes EmployerStaffRole from John/ do |name|
  staff = Person.where(first_name: name).first
  accept_alert do
    find_all('.fa-trash-alt')[0].click
  end
end

When /(\w+) approves EmployerStaffRole for (\w+)/ do |staff1, staff2|
  staff = Person.where(first_name: staff2).first
  find('#approve_' + staff.id.to_s).click
  screenshot('before_approval')
  expect(find('.alert-notice').text).to match /Role is approved/
  screenshot('after_approval')
end

Then /(\w+) sees new employer page/ do |ex_staff|
  match = current_path.match  /employers\/employer_profiles\/new/
  expect(match.present?).to be_truthy
end

Then /(\w+) enters data for Turner Agency, Inc/ do |name|
  @fein = Organization.where(legal_name: /Turner Agency, Inc/).first.fein
  step 'NewGuy enters Employer Information'
end

Then /(\w+) is notified about Employer Staff Role (.*)/ do |name, alert|
  expect(page).to have_content("Thank you for submitting your request to access the employer account. Your application for access is pending.")
  expect(page).to have_css("a", :text => /back/i)
  screenshot('pending_person_stays_on_new_page')
end

Given /Admin accesses the Employers tab of HBX portal/ do
  visit '/'
  portal_class = '.interaction-click-control-hbx-portal'
  find(portal_class).click

  step "Admin signs in to portal"
  tab_class = '.interaction-click-control-employers'
  find(tab_class, wait: 10).click
end

Given(/the user is on the Admin Tab of the Admin Dashboard/) do
  visit '/'
  portal_class = '.interaction-click-control-hbx-portal'
  find(portal_class).click
  step "Admin signs in to portal"
  tab_class = '.interaction-click-control-admin'
  find(tab_class, wait: 10).click
end

Given("the user is on the User Accounts tab of the Admin Dashboard") do
  visit exchanges_hbx_profiles_path
  tab_class = '.interaction-click-control-user-accounts'
  find(tab_class, wait: 10).click
end

Given /Admin selects Hannahs company/ do
  company = find('a', text: 'Turner Agency, Inc', :wait => 3)
  company.click
end

Then("user will click on action tab") do
  sleep 5
  find('.dropdown.pull-right', text: 'Actions', wait: 10, match: :first).click
end

Given /(\w+) has HBXAdmin privileges/ do |name|
  person = Person.where(first_name: name).first
  role = FactoryBot.create(:hbx_staff_role, person: person)
  Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                    send_broker_agency_message: true, approve_broker: true, approve_ga: true,
                    modify_admin_tabs: true, view_admin_tabs: true)
  role.update_attributes(permission_id: Permission.hbx_staff.id)

end

Given /a FEIN for an existing company/ do
  SicCode.where(sic_code: '0111').first || FactoryBot.create(:sic_code, sic_code: "0111")
  @fein = 100000000+rand(10000)
  o=FactoryBot.create(:organization, fein: @fein)
  @employer_profile= FactoryBot.create(:employer_profile, organization: o)
end

Given /a FEIN for a new company/ do
  @fein = 100000000+rand(10000)
end
Given(/^(\w+) enters Employer Information/) do |name|
  fill_in 'agency[organization][legal_name]', :with => Forgery('name').company_name
  fill_in 'agency[organization][dba]', :with => Forgery('name').company_name
  fill_in 'agency[organization][fein]', :with => @fein
  select 'Tax Exempt Organization', from: 'agency_organization_entity_kind'
  select "0111", from: "agency_organization_profile_attributes_sic_code"
  step "I enter office location for #{default_office_location}"
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][area_code]', :with => '202'
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][number]', :with => '5551212'
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][extension]', :with => '22332'
  select 'Billboard', from: 'referred-by-select'

  find_button("Confirm").click
end

Then /(\w+) becomes an Employer/ do |name|
  find('a', text: "I'm an Employer")
end

Then /there is a linked POC/ do
  find('td', text: /Linked/)
end

Then /there is an unlinked POC/ do
  find('td', text: /Unlinked/)
end

AfterStep do |scenario|
  sleep 1 if ENV['SCREENSHOTS'] == "true"
  screenshot("")
end
