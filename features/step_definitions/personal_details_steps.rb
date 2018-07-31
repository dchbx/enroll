Then(/Employee (.*) should click Manage Family/) do |named_person|
  find('a.interaction-click-control-manage-family').click
end

Then(/Employee (.*) should click the Personal Tab/) do |named_person|
  find('a.interaction-click-control-personal').click
end

Then(/Employee (.*) should click Change my Password/) do |named_person|
  find('a.interaction-click-control-change-my-password').click
  wait_for_ajax
end

Then(/Employee (.*) should click Update my security challenge responses/) do |named_person|
  find('a.interaction-click-control-update-my-security-challenge-responses').click
  wait_for_ajax
end

Then(/they can submit a new password/) do
  fill_in 'user[password]', with: 'aA1!aA1!aA1!'
  fill_in 'user[new_password]', with: 'NewPass!@#$1234'
  fill_in 'user[password_confirmation]', with: 'NewPass!@#$1234'
  page.find_button('Change my password').trigger('click')
  wait_for_ajax
end

Then(/they attempt to submit a new password/) do
  fill_in 'user[password]', with: 'thisisnotthepassword'
  fill_in 'user[new_password]', with: 'NewPass!@#$1234'
  fill_in 'user[password_confirmation]', with: 'NewPass!@#$1234'
  page.find_button('Change my password').trigger('click')
  wait_for_ajax
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
