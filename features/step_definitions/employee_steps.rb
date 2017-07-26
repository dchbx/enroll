Given (/a matched Employee exists with only employee role/) do
  FactoryGirl.create(:user)
  FactoryGirl.create(:person, :with_employee_role, :with_family, first_name: "Employee", last_name: "E", user: user)
end

Given (/a person exists with dual roles/) do
  FactoryGirl.create(:user)
  FactoryGirl.create(:person, :with_employee_role, :with_consumer_role, :with_family, first_name: "Dual Role Person", last_name: "E", user: user)
end

Then (/(.*) sign in to portal/) do |name|
  user = Person.where(first_name: "#{name}").first.user
  login_as user
  visit "/families/home"
end

And (/Employee should see a button to enroll in ivl market/) do
  expect(page).to have_content "Enroll in health or dental coverage on the District of Columbia's individual market"
  expect(page).to have_link "Enroll"
end

Then (/Dual Role Person should not see any button to enroll in ivl market/) do
  expect(page).not_to have_content "Enroll in health or dental coverage on the District of Columbia's individual market"
  expect(page).not_to have_link "Enroll"
end

And (/Employee clicks on Enroll/) do
  click_link "Enroll"
end

Then (/Employee redirects to ivl flow/) do
  expect(page).to have_content("Personal Information")
end
