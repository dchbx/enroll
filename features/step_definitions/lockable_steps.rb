Then(/^there are (\d+) preloaded (.*?) user accounts$/) do |num, status|
  (0...num.to_i).each do |int|
    user = FactoryGirl.create(:user, :with_family)
    user.lock! if status.eql?('locked')
  end
end

Then(/^there are (\d+) preloaded user accounts without the email$/) do |num|
  (0...num.to_i).each do |int|
    FactoryGirl.create(:user, :without_email, :with_family)
  end
end

Then(/^Hbx Admin should see (.*?) link on user accounts page$/) do |text|
  find_link(text).visible?
end

When(/^Hbx Admin clicks on (.*?) link on user accounts page$/) do |link|
  click_link(link)
  wait_for_ajax
end

Then(/^there is a confirm (.*?) should be visible$/) do |type|
  send("find_#{type}", 'Confirm').visible?
end

Then(/^there is a text field should be visible$/) do
  within('.child-row') do
    expect(page).to have_css('#user_email', count: 1)
  end
end

Then(/^I fill the (.*?) email address for that user$/) do |email|
  fill_in 'user_email', with: email
end

When(/^I click on the confirm link$/) do
  find(:link, 'Confirm').trigger 'click'
  wait_for_ajax
  sleep 2
end

When 'I click on the confirm button' do
  find(:button, 'Confirm').trigger 'click'
  wait_for_ajax
  sleep 1
end

Then(/^the (.*?) user should be in the list$/) do |status|
  within('table.effective-datatable tbody') do
    page.all('table.effective-datatable tbody tr').last.should(have_content(status))
  end
end

Then(/^the error (.*?) should be raised$/) do |error|
  within('.child-row') do
    expect(page).to have_content(error)
  end
end

Then(/^the user email should be (.*?)$/) do |email|
  expect(User.all.to_a.last.email).to eq email
end
