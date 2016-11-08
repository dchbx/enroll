Given /(\w+) is a person$/ do |name|
  person = FactoryGirl.create(:person, first_name: name)
  @pswd = 'aA1!aA1!aA1!'
  email = Forgery('email').address
  user = User.create(email: email, password: @pswd, password_confirmation: @pswd, person: person, oim_id: email)
end
And /(\w+) also has a duplicate person with different DOB/ do |name|
  person = Person.where(first_name: name).first
  FactoryGirl.create(:person, first_name: person.first_name,
            last_name: person.last_name, dob: '06/06/1976')
end
Given /(\w+) is a person who has not logged on$/ do |name|
  person = FactoryGirl.create(:person, first_name: name)
end

Then  /(\w+) signs in to portal/ do |name|
  person = Person.where(first_name: name).first
  fill_in "user[login]", :with => person.user.email
  find('#user_login').set(person.user.email)
  fill_in "user[password]", :with => @pswd
  #TODO this fixes the random login fails b/c of empty params on email
  fill_in "user[login]", :with => person.user.email unless find(:xpath, '//*[@id="user_login"]').value == person.user.email
  find('.interaction-click-control-sign-in').click
end

Given /(\w+) is a user with no person who goes to the Employer Portal/ do |name|
  email = Forgery('email').address
  visit '/'
  portal_class = '.interaction-click-control-employer-portal'
  find(portal_class).click
  @pswd = 'aA1!aA1!aA1!'
  fill_in "user[oim_id]", :with => email
  fill_in "user[password]", :with => @pswd
  fill_in "user[password_confirmation]", :with => @pswd

  find(:xpath, '//label[@for="user_email_or_username"]').set(email)
  # find('#user_email_or_username').set(email)
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
  #fill_in('organization[first_name]').click
  fill_in 'organization[email]', with: Forgery('internet').email_address
  fill_in 'organization[area_code]', with: 202
  fill_in 'organization[number]', with: '555-1212'
end

Given /(\w+) matches with different DOB from employer staff role/ do |name|
  person = Person.where(first_name: name).first
  fill_in 'organization[first_name]', with:  person.first_name
  fill_in 'organization[last_name]', with: person.last_name
  fill_in 'jq_datepicker_ignore_organization[dob]', with: '03/03/1993'
  #fill_in('organization[first_name]').click
  fill_in 'organization[email]', with: Forgery('internet').email_address
  fill_in 'organization[area_code]', with: 202
  fill_in 'organization[number]', with: '555-1212'
end

Then(/(\w+) is the staff person for an employer$/) do |name|
  person = Person.where(first_name: name).first
  employer_profile = FactoryGirl.create(:employer_profile)
  employer_staff_role = FactoryGirl.create(:employer_staff_role, person: person, employer_profile_id: employer_profile.id)
end


Then(/(\w+) is the staff person for an existing employer$/) do |name|
  person = Person.where(first_name: name).first
  employer_staff_role = FactoryGirl.create(:employer_staff_role, person: person, employer_profile_id: @employer_profile.id)
end

Then(/(\w+) is applicant staff person for an existing employer$/) do |name|
  person = Person.where(first_name: name).first
  employer_staff_role = FactoryGirl.create(:employer_staff_role, person: person, employer_profile_id: @employer_profile.id, aasm_state: 'is_applicant')
end

When(/(\w+) accesses the Employer Portal/) do |name|
  person = Person.where(first_name: name).first
  visit '/'
  portal_class = 'interaction-click-control-employer-portal'
  find("a.#{portal_class}").click
  find('.interaction-click-control-sign-in-existing-account').click
  step "#{name} signs in to portal"
end

Then /(\w+) decides to Update Business information/ do |person|
  find('.interaction-click-control-update-business-info', :wait => 10).click
  wait_for_ajax(10,2)
  screenshot('update_business_info')
end

Given /(\w+) adds an EmployerStaffRole to (\w+)/ do |staff, new_staff|
  person = Person.where(first_name: new_staff).first
  click_link 'Add Employer Staff Role'
  fill_in 'first_name', with: person.first_name
  fill_in 'last_name', with: person.last_name
  fill_in  'dob', with: person.dob
  screenshot('add_existing_person_as_staff')
  find('.interaction-click-control-save').click
  step 'Point of Contact count is 2'
end

Then /Point of Contact count is (\d+)/ do |count|
  expect(page.all('tr').count - 1).to eq(count.to_i)
end

Then /Hannah cannot remove EmployerStaffRole from Hannah/ do
  staff = Person.where(first_name: 'Hannah').first
  page.execute_script("window.confirm = function() {return true}")
  find('#delete_' + staff.id.to_s).click

end
When /(\w+) removes EmployerStaffRole from (\w+)/ do |staff1, staff2|
  staff = Person.where(first_name: staff2).first
  page.execute_script("window.confirm = function() {return true}")
  find('#delete_' + staff.id.to_s).click
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
  find('.interaction-click-control-sign-in-existing-account').click
  step "Admin signs in to portal"
  tab_class = '.interaction-click-control-employers'
  find(tab_class).click
end
Given /Admin selects Hannahs company/ do
  company = find('a', text: 'Turner Agency, Inc')
  company.click
end

Given /(\w+) has HBXAdmin privileges/ do |name|
  person = Person.where(first_name: name).first
  role = FactoryGirl.create(:hbx_staff_role, person: person)
  Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true)
  role.update_attributes(permission_id: Permission.hbx_staff.id)
end

Given /a FEIN for an existing company/ do
  @fein = 100000000+rand(10000)
  o=FactoryGirl.create(:organization, fein: @fein)
  @employer_profile= FactoryGirl.create(:employer_profile, organization: o)
end

Given /a FEIN for a new company/ do
  @fein = 100000000+rand(10000)
end

Given(/^(\w+) enters Employer Information/) do |name|
  fill_in 'organization[legal_name]', :with => Forgery('name').company_name
  fill_in 'organization[dba]', :with => Forgery('name').company_name
  fill_in 'organization[fein]', :with => @fein
  find('.selectric-interaction-choice-control-organization-entity-kind').click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'C Corporation')]").click
  step "I enter office location for #{default_office_location}"
  fill_in 'organization[office_locations_attributes][0][phone_attributes][area_code]', :with => '202'
  fill_in 'organization[office_locations_attributes][0][phone_attributes][number]', :with => '5551212'
  fill_in 'organization[office_locations_attributes][0][phone_attributes][extension]', :with => '22332'
  find('.interaction-click-control-confirm').click
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
