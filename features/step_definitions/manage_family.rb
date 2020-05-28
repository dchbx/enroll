Given(/^Employer exists and logs in$/) do
  login_as @staff_role
end

Then(/^Employee should click on Manage Family button$/) do
  find('a.interaction-click-control-manage-family').click
end

Then(/^Employee should click on the Personal Tab link$/) do
  find('a.interaction-click-control-personal').click
end

Then(/^Employee should click on Change my Password link$/) do
  if aca_security_questions
    wait_for_ajax
    page.execute_script("document.querySelector('#change_password_link').click()")
  end
end

Then(/they can submit a new password/) do
  fill_in 'user[password]', with: "aA1!aA1!aA1!"
  sleep 1
  fill_in 'user[new_password]', with: "NewPass!@$1234"
  sleep 1
  fill_in 'user[password_confirmation]', with: "NewPass!@$1234"
  sleep 1
  page.find_button('Change my password').click
end

Then(/^Employee will submit with wrong password$/) do
  fill_in 'user[password]', with: 'aA1!aA1!'
  fill_in 'user[new_password]', with: 'NewPass!@#$1234'
  fill_in 'user[password_confirmation]', with: 'NewPass!@#$1234'
  sleep 1
  page.find_button('Change my password').click
end

And(/^Employee (.*) replaces their spouse personal information with that of their child$/) do |named_person|
  # Click the family tab
  click_link 'Family'
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
  spouse = person_record.person_relationships.where(kind: "spouse").first.relative
  # The edit link
  find("a[title='Edit Dependent #{spouse.full_name}']").click
  fill_in('dependent[first_name]', with: "Amanda")
  fill_in('dependent[last_name]', with: "Doe")
  fill_in('jq_datepicker_ignore_dependent[dob]', with: "01/01/2019")
  fill_in('dependent[ssn]', with: "994857643")
  select("child", from: "dependent[relationship]")
end

Then(/^the family of (.*) does not contain two new family members or person records with the spouse HBX ID$/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
  family_record = person_record.primary_family
  spouse = person_record.person_relationships.where(kind: "spouse").first.relative
  spouse_hbx_id = spouse.hbx_id.to_s
  spouse_person_id = spouse.id.to_s
  family_member_hbx_ids = family_record.family_members.map { |fm| fm.hbx_id.to_s }
  family_member_spouse_hbx_id_count = []
  family_member_hbx_ids.each { |id| family_member_spouse_hbx_id_count << id if id == spouse_hbx_id }
  expect(family_member_spouse_hbx_id_count.length).to eq(1)
  family_member_person_ids = family_record.family_members.map { |fm| fm.person_id.to_s }
  family_member_spouse_person_id_count = []
  family_member_person_ids.each { |id| family_member_spouse_person_id_count << id if id == spouse_person_id }
  expect(family_member_spouse_person_id_count.length).to eq(1)
end    

Then(/the Employee should see a message that they were not able to create the spouse because they are a duplicate$/) do 
  expect(page).to have_content("can not have multiple spouse or life partner")
end

Then(/^they should see a password does not match error$/) do
  expect(page).to have_text "That password does not match the one we have stored"
end

Then(/^I should see page redirected to Manage Family$/) do
  expect(page).to have_text "Manage Family"
end

Then(/Employee should not see phone main field in the personal information fields/) do
  expect(page).not_to have_content(/Phone Main/)
end

And(/Employee (.*) should only have phone with work kind/) do |named_person|
  person = people[named_person]
  person = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
  expect(person.phones.where(kind: "phone main").blank?).to eq(true)
  expect(person.phones.first.kind).to eq("work")
end
