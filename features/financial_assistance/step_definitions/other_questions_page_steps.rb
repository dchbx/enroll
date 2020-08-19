Given(/^the user will navigate to the FAA Household Info page$/) do
  visit edit_financial_assistance_application_path(application.id.to_s)
end

Given(/^the user SSN is nil$/) do
  consumer.person.update_attributes(no_ssn: "1")
end

Given(/^the user has an eligible immigration status$/) do
  consumer.person.consumer_role.update_attributes(citizen_status: "alien_lawfully_present")
end

Given(/^the user has an age between (\d+) and (\d+) years old$/) do |arg1, arg2|
  consumer.person.update_attributes(dob: TimeKeeper.date_of_record - 19.years)
end

Then(/^the have you applied for an SSN question should display$/) do
  expect(page).to have_content('Has this person applied for an SSN *')
end

And(/^the user answers no to the have you applied for an SSN question$/) do
  choose('is_ssn_applied_no')
end

Then(/^the reason why question is displayed$/) do
  expect(page).to have_content('Why doesn\'t this person have an SSN?')
end

Given(/^the user answers yes to being pregnant$/) do
  choose('is_pregnant_yes')
end

Then(/^the due date question should display$/) do
  expect(page).to have_content('Pregnancy due date')
end

And(/^how many children question should display$/) do
  expect(page).to have_content('How many children is this person expecting?')
end

Given(/^the user answers no to being pregnant$/) do
  choose('is_pregnant_no')
end

And(/^was this person pregnant in the last (\d+) days question should display$/) do |arg1|
  expect(page).to have_content('Was this person pregnant in the last 60 days?')
end

When(/^they answer yes to was this person pregnant in the last (\d+) days question$/) do |arg1|
  choose('is_post_partum_period_yes')
end

Then(/^pregnancy end date question should display$/) do
  expect(page).to have_content('Pregnancy end on date')
end

Then(/^the is this person a student question should display$/) do
  expect(page).to have_content('Is this person a student? *')
end

Given(/^the user answers yes to being a student$/) do
  choose('is_student_yes')
end

And(/^the type of student question should display$/) do
  expect(page).to have_content('What is the type of student?')
end

And(/^student status end date question should display$/) do
   expect(page).to have_content('Student status end on date?')
end

Then(/^type of school question should display$/) do
  expect(page).to have_content('What type of school do you go to?')
end

Then(/^the has this person ever been in foster care question should display$/) do
  expect(page).to have_content('Was this person in foster care at age 18 or older? *')
end

Given(/^the user answered yes to the has this person ever been in foster care question$/) do
  choose('is_former_foster_care_yes')
end

Then(/^the where was this person in foster care question should display$/) do
  expect(page).to have_content('Where was this person in foster care?')
end

Then(/^the how old was this person when they left foster care question should display$/) do
  expect(page).to have_content('How old was this person when they left foster care?')
end

Then(/^the was this person enrolled in medicare when they left foster care should display$/) do
  expect(page).to have_content('Was this person enrolled in Medicaid when they left foster care?')
end

And(/^the user answers yes to having an eligible immigration status$/) do
  consumer.person.eligible_immigration_status == true
end

Then(/^the did you move to the US question should display$/) do
  expect(page).to have_content('Did you move to the U.S. on or after August 22, 1996?')
end

Then(/^the military veteran question should display$/) do
  expect(page).to have_content('Are you an honorably discharged veteran or active duty member of the military?')
end

Given(/^user answers yes to the military veteran question$/) do
  choose('is_resident_post_092296_yes')
end

Then(/^the are you a spouse of such a veteran question should display$/) do
  expect(page).to have_content('Are you an honorably discharged veteran or active duty member of the military?')
end
