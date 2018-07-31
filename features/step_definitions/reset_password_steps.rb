Then(/^Hbx Admin should see the list of primary applicants and Action buttons$/) do
  within('.effective-datatable') do
    expect(page).to have_css('.dropdown-toggle', count: 2)
  end
end

When(/^Hbx Admin clicks on the Action button of primary applicant$/) do
  within('.effective-datatable') do
    find_all('.dropdown-toggle').last.click
  end
end

Then(/^Hbx Admin should see (.*?) link in action drop down$/) do |text|
  find_link(text).visible?
end

When(/^Hbx Admin clicks on (.*?) link in action drop down$/) do |link|
  click_link(link)
  wait_for_ajax
end

And(/^Hbx admin confirms password send/) do
  find('.lock-confirm-btn').trigger('click')
  wait_for_ajax
end

Then(/^the reset password email should be sent to the user$/) do
  expect(User.all.to_a.last.reset_password_token).to be_a String
end

Then(/^there are (\d+) preloaded user accounts without email$/) do |num|
  (0...num.to_i).each do |int|
    FactoryGirl.create(:user, :without_email, :with_family)
  end
end

Then(/^Hbx Admin can see the enter email for reset password modal$/) do
  page.should have_content 'Please enter email for sending reset password instruction'
end

Then(/^Hbx Admin fill the (.*?) email address for that user$/) do |email|
  fill_in 'user_email', with: email
end

Then(/^an error (.*?) should be raised$/) do |error|
  within('.alert-danger') do
    expect(page).to have_content(error)
  end
end

When 'Hbx Admin submit the reset password modal form' do
  click_button('Submit')
  wait_for_ajax
end

Then(/^the primary applicant email should be (.*?)$/) do |email|
  expect(User.all.to_a.last.email).to eq email
end
