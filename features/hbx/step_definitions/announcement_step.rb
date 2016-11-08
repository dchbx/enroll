And /^Hbx admin should see the link of announcements and click$/ do
  click_link 'Config'
  wait_for_ajax
  expect(page).to have_content("Announcements")
  click_link 'Announcements'
end

Then /^Hbx admin should see the page of announcements$/ do
  expect(page).to have_content("Current Announcements")
  expect(page).to have_content("Msg Start Date")
end

When(/Hbx admin enter announcement info$/) do
  fill_in 'announcement[content]', with: 'announcement for current'
  fill_in 'jq_datepicker_ignore_announcement[start_date]', with: (TimeKeeper.date_of_record - 5.days).to_s
  fill_in 'jq_datepicker_ignore_announcement[end_date]', with: (TimeKeeper.date_of_record + 5.days).to_s
  find('#announcement_audiences_ivl').click
  find('.interaction-click-control-create-announcement').click
end

When(/^Hbx admin enter announcement info with future date$/) do
  fill_in 'announcement[content]', with: 'announcement for future'
  fill_in 'jq_datepicker_ignore_announcement[start_date]', with: (TimeKeeper.date_of_record + 5.days).to_s
  fill_in 'jq_datepicker_ignore_announcement[end_date]', with: (TimeKeeper.date_of_record + 15.days).to_s
  find('#announcement_audiences_ivl').click
  find('.interaction-click-control-create-announcement').click
end

Then(/Hbx admin should see the current announcement/) do
  wait_for_ajax
  expect(page).to have_content('announcement for current')
  expect(page).to have_content('IVL')
end

Then(/^Hbx admin should not see the future announcement$/) do
  expect(page).not_to have_content('announcement for future')
end

When(/^Hbx admin enter announcement info with invalid params$/) do
  fill_in 'announcement[content]', with: 'invalid announcement'
  fill_in 'jq_datepicker_ignore_announcement[start_date]', with: (TimeKeeper.date_of_record + 5.days).to_s
  fill_in 'jq_datepicker_ignore_announcement[end_date]', with: (TimeKeeper.date_of_record).to_s
  find('#announcement_audiences_ivl').click
  find('.interaction-click-control-create-announcement').click
end

Then(/^Hbx admin should see the alert msg$/) do
  expect(page).to have_content('prohibited this announcement from being saved')
  expect(page).to have_content('End Date should be later than Start date')
end

When(/^Hbx admin click the link of all$/) do
  click_link "All"
end

Then(/^Hbx admin should see the future announcement$/) do
  expect(page).to have_content('announcement for future')
end

Then(/^.+ should see announcement$/) do
  expect(page).to have_content('msg content')
end

When(/^Consumer click the link of documents$/) do
  find('.interaction-click-control-documents').click
end

When(/^Consumer click the link of homepage$/) do
  find('.interaction-click-control-my-dc-health-link').click
end

Given(/^Consumer role exists$/) do
  user = FactoryGirl.create :user, :with_family, :consumer, email: 'consumer@dc.gov', password: '1qaz@WSX', password_confirmation: '1qaz@WSX', idp_verified: true
  FactoryGirl.create(:consumer_role, person: user.person)
end

Given(/^Employer role exists$/) do
  employer_profile = FactoryGirl.create :employer_profile
  user = FactoryGirl.create :user, :with_family, :employer_staff, email: 'employer@dc.gov', password: '1qaz@WSX', password_confirmation: '1qaz@WSX'
  FactoryGirl.create :employer_staff_role, person: user.person, employer_profile_id: employer_profile.id
end

Then(/^.+ should not see announcement$/) do
  expect(page).not_to have_content('msg content')
end

When(/^Employer login$/) do
  visit "/"
  click_link "Employer Portal"
  find('.interaction-click-control-sign-in-existing-account').click

  fill_in "user[login]", :with => 'employer@dc.gov'
  find('#user_login').set('employer@dc.gov')
  fill_in "user[password]", :with => '1qaz@WSX'
  fill_in "user[login]", :with => 'employer@dc.gov' unless find(:xpath, '//*[@id="user_login"]').value == 'employer@dc.gov'
  find('.interaction-click-control-sign-in').click
end

Given(/^Announcement prepared for Consumer role$/) do
  FactoryGirl.create :announcement, audiences: ['IVL'], content: 'msg content'
end

When(/^Consumer login$/) do
  visit "/"
  click_link "Consumer/Family Portal"
  wait_for_ajax
  find('.interaction-click-control-sign-in-existing-account').click

  fill_in "user[login]", :with => 'consumer@dc.gov'
  find('#user_login').set('consumer@dc.gov')
  fill_in "user[password]", :with => '1qaz@WSX'
  fill_in "user[login]", :with => 'consumer@dc.gov' unless find(:xpath, '//*[@id="user_login"]').value == 'consumer@dc.gov'
  find('.interaction-click-control-sign-in').click
end

