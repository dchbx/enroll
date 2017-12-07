
When(/^the user has a family with e_case_id and visit personal information edit page$/) do
  person = FactoryGirl.create(:person, first_name: "sarah")
  person2 = FactoryGirl.create(:person, :with_consumer_role, first_name: "mahesh")
  family = FactoryGirl.create(:family, :with_primary_family_member, person: person2, e_case_id: "e_case_id")
  current_user = FactoryGirl.create(:user, :hbx_staff, person: person)
  expect(person2.primary_family.e_case_id).to eq("e_case_id")
  visit edit_insured_consumer_role_path(person2.consumer_role.id)
end

When(/^the applicant with no e_case_id and visit personal information edit page$/) do
  allow_any_instance_of(ConsumerRolePolicy).to receive(:can_view_application_types?).and_return(true)
end

When(/^the applicant with no e_case_id and visit personal information edit page$/) do
  allow_any_instance_of(ConsumerRolePolicy).to receive(:can_view_application_types?).and_return(true)
end

Then(/^EA will automatically populate the Application Type as CURAM$/) do
  expect(page).to have_content("Curam")
  find(:xpath, "//p[@class='label'][contains(., 'Curam')]").click
end

Then(/^EA will display all the Application Types$/) do
  expect(page).to have_css("#application_type_id")
  find(:xpath, "//p[@class='label'][contains(., 'choose')]").click
  find(:xpath, "//select[@name='person[family][application_type]']/option[@value='Phone']")
  find(:xpath, "//select[@name='person[family][application_type]']/option[@value='In Person']")
  find(:xpath, "//select[@name='person[family][application_type]']/option[@value='Paper']")
  find(:xpath, "//select[@name='person[family][application_type]']/option[@value='Curam']")
  find(:xpath, "//select[@name='person[family][application_type]']/option[@value='Mobile']")
end

When(/^the Admin selects the Curam application option$/) do
  find(:xpath, "//select[@name='person[family][application_type]']/option[@value='Curam']")
end

Then(/^the Admin should navigate to Household Info Page$/) do
  expect(page).to have_content("Household Info")
end

When(/^the Admin selects the Mobile application option$/) do
  find(:xpath, "//select[@name='person[family][application_type]']/option[@value='Mobile']")
end
