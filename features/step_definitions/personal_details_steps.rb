Then(/Employee (.*) should click Manage Family/) do |named_person|
  find('a.interaction-click-control-manage-family').click
end

Then(/Employee (.*) should click the Personal Tab/) do |named_person|
  find('a.interaction-click-control-personal').click
end

Then(/Employee (.*) should click Change my Password/) do |named_person|
  if aca_security_questions
    wait_for_ajax
    page.execute_script("document.querySelector('#change_password_link').click()")
  end
end

Then(/Employee (.*) should click Update my security challenge responses/) do |named_person|
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

And(/they should see a password error message/) do
  expect(page).to have_text 'That password does not match the one we have stored'
end

Then(/I should see a security response success message/) do
  expect(page).to have_text 'Security responses successfully updated'
end

And(/that a person with (.*) exists in EA/) do |role|

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

And(/person with (.*) signs in and visits manage account/) do |role|
  person = Person.where(first_name: role.split(/\s/)[0]).first
  user = person.user
  login_as user
  visit "/people/#{person.id}/manage_account"
end

And(/person clicks on personal info section/) do
  click_link 'Personal Info'
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
