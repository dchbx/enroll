Then(/^Hbx Admin should see buttons to filter$/) do
  expect(page).to have_content('Employee')
  expect(page).to have_content('Broker')
  expect(page).to have_content('Employer')
  expect(page).to have_content('All')
  expect(page).to have_content('CSV')
  # at present we do not have clear implementation thoughts about bulk action on user account data-table
  # expect(page).to have_content('Bulk Actions')
end

Then(/^Hbx Admin should see text Account Updates$/) do
  expect(page).to have_content('Account Updates')
end

Then(/^Hbx Admin should see columns related to user account$/) do
  expect(page).to have_content('USERNAME')
  expect(page).to have_content('SSN')
  expect(page).to have_content('DOB')
  expect(page).to have_content('HBX ID')
  expect(page).to have_content('EMAIL')
  expect(page).to have_content('Status')
  expect(page).to have_content('Role Type')
  expect(page).to have_content('Actions')
end

And(/^a user exists with employer staff role$/) do
  FactoryGirl.create :user, :employer_staff, oim_id: "test_employer", email: 'employer1@dc.gov', password: '1qaz@WSX', password_confirmation: '1qaz@WSX'
end

And(/^a user exists with employee role$/) do
  FactoryGirl.create :user, :employee, oim_id: 'test_employee', email: 'employe31@dc.gov', password: '1q23az@WSX', password_confirmation: '1q23az@WSX'
end

And(/^a user exists with broker role$/) do
  FactoryGirl.create :user, :broker_with_person, oim_id: 'test_broker', email: 'broker2331@dc.gov', password: '112q24az@WSX', password_confirmation: '112q24az@WSX'
end

And(/^a locked user exists with employer staff role$/) do
  FactoryGirl.create :user, :employer_staff, oim_id: "test1_employer1", email: 'employer11@dc.gov', password: '11qaz@WSX', password_confirmation: '11qaz@WSX', locked_at: Date.today
end

And(/^a locked user exists with employee role$/) do
  FactoryGirl.create :user, :employee, oim_id: 'test1_employee1', email: 'employe311@dc.gov', password: '11q24az@WSX', password_confirmation: '11q24az@WSX', locked_at: Date.today
end

And(/^a locked user exists with broker role$/) do
  FactoryGirl.create :user, :broker_with_person, oim_id: 'test1_broker1', email: 'broker23311@dc.gov', password: '1412q24az@WSX', password_confirmation: '1412q24az@WSX', locked_at: Date.today
end

When(/^I click Employee button$/)do
  find(:xpath, '//*[@id="Tab:all_employee_roles"]').click 
end

When(/^I click Employee and Locked button$/)do
  find(:xpath, '//*[@id="Tab:all_employee_roles"]').click
  find(:xpath, '//*[@id="Tab:all_employee_roles-locked"]').click 
end

When(/^I click Employee and Unlocked button$/)do
  find(:xpath, '//*[@id="Tab:all_employee_roles-unlocked"]').click 
end

Then(/^I should only see user with employee role$/)do
  employee_user = User.where(:'roles'.in => ["employee"]).first.oim_id
  employer_user = User.where(:'roles'.in => ["employer_staff"]).first.oim_id
  broker_user = User.where(:'roles'.in => ["broker"]).first.oim_id
  expect(page).to have_content(employee_user)
  expect(page).not_to have_content(employer_user)
  expect(page).not_to have_content(broker_user)
  expect(page).to have_content("Locked")
  expect(page).to have_content("Unlocked")
end

When(/^I click All button$/)do
  find(:xpath, '//*[@id="Tab:all"]').click 
end

Then(/^I should only see locked user with employee role$/)do
  locked_employee_user = User.where(:'roles'.in => ["employee"], :locked_at.ne => nil).first.oim_id
  locked_employer_user = User.where(:'roles'.in => ["employer_staff"], :locked_at.ne => nil).first.oim_id
  locked_broker_user = User.where(:'roles'.in => ["broker"], :locked_at.ne => nil).first.oim_id
  employee_user = User.where(:'roles'.in => ["employee"], locked_at: nil).first.oim_id
  employer_user = User.where(:'roles'.in => ["employer_staff"], locked_at: nil).first.oim_id
  broker_user = User.where(:'roles'.in => ["broker"], locked_at: nil).first.oim_id
  expect(page).not_to have_content(employee_user)
  expect(page).not_to have_content(employer_user)
  expect(page).not_to have_content(broker_user)
  expect(page).not_to have_content(locked_employer_user)
  expect(page).to have_content(locked_employee_user)
  expect(page).not_to have_content(locked_broker_user)
end

Then(/^I should only see unlocked user with employee role$/)do
  locked_employee_user = User.where(:'roles'.in => ["employee"], :locked_at.ne => nil).first.oim_id
  locked_employer_user = User.where(:'roles'.in => ["employer_staff"], :locked_at.ne => nil).first.oim_id
  locked_broker_user = User.where(:'roles'.in => ["broker"], :locked_at.ne => nil).first.oim_id
  employee_user = User.where(:'roles'.in => ["employee"], locked_at: nil).first.oim_id
  employer_user = User.where(:'roles'.in => ["employer_staff"], locked_at: nil).first.oim_id
  broker_user = User.where(:'roles'.in => ["broker"], locked_at: nil).first.oim_id
  expect(page).to have_content(employee_user)
  expect(page).not_to have_content(employer_user)
  expect(page).not_to have_content(broker_user)
  expect(page).not_to have_content(locked_employer_user)
  expect(page).to have_content("test_employee")
  expect(page).not_to have_content(locked_broker_user)
end


Then(/^I should only see user with all roles$/)do
  employee_user = User.where(:'roles'.in => ["employee"]).first.oim_id
  employer_user = User.where(:'roles'.in => ["employer_staff"]).first.oim_id
  broker_user = User.where(:'roles'.in => ["broker"]).first.oim_id
  expect(page).to have_content(employee_user)
  expect(page).to have_content(employer_user)
  expect(page).to have_content(broker_user)
  expect(page).to have_content("Locked")
  expect(page).to have_content("Unlocked")
end

When(/^I click Employer button$/)do
  find(:xpath, '//*[@id="Tab:all_employer_staff_roles"]').click 
end

Then(/^I should only see user with employer staff role$/)do
  employee_user = User.where(:'roles'.in => ["employee"]).first.oim_id
  employer_user = User.where(:'roles'.in => ["employer_staff"]).first.oim_id
  broker_user = User.where(:'roles'.in => ["broker"]).first.oim_id
  expect(page).not_to have_content(employee_user)
  expect(page).to have_content(employer_user)
  expect(page).not_to have_content(broker_user)
  expect(page).to have_content("Locked")
  expect(page).to have_content("Unlocked")
end

When(/^I click Broker button$/)do
  find(:xpath, '//*[@id="Tab:all_broker_roles"]').click 
end

Then(/^I should only see user with broker role$/)do
  employee_user = User.where(:'roles'.in => ["employee"]).first.oim_id
  employer_user = User.where(:'roles'.in => ["employer_staff"]).first.oim_id
  broker_user = User.where(:'roles'.in => ["broker"]).first.oim_id
  expect(page).not_to have_content(employee_user)
  expect(page).not_to have_content(employer_user)
  expect(page).to have_content(broker_user)
  expect(page).to have_content("Locked")
  expect(page).to have_content("Unlocked")
end

When(/^a user enters an user name search box$/)do
  page.find("input[type='search']").set(@user_1.oim_id)
end

Then(/^a user should see a result with the user name$/) do
  expect(page).to have_content(@user_1.oim_id)
  expect(page).to have_no_content(@user_2.oim_id)
end

When(/^a user enter person hbx id$/)do
  page.find("input[type='search']").set(@user_1.email)
end

Then(/^a user should see a result with hbx id$/) do
  expect(page).to have_content(@user_1.email)
  expect(page).to have_no_content(@user_2.email)
end