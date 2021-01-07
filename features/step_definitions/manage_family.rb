Given(/^Employer exists and logs in$/) do
  login_as @staff_role
end

Then(/^Employee should click on Manage Family button$/) do
  find('a.interaction-click-control-manage-family').click
end

Then(/^Employee should click on the Personal Tab link$/) do
  find('a.interaction-click-control-personal').click
end

Then(/^Employee should not see the Ageoff Exclusion checkbox$/) do
  expect(page).not_to have_content(/Ageoff Exclusion/)
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
