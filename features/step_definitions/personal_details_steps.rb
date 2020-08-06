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

And(/they should see a password error message/) do
  expect(page).to have_text 'That password does not match the one we have stored'
end

Then(/I should see a security response success message/) do
  expect(page).to have_text 'Security responses successfully updated'
end
