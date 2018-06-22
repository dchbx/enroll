Given (/a matched Employee exists with only employee role/) do
  FactoryGirl.create(:user)
  person = FactoryGirl.create(:person, :with_employee_role, :with_family, first_name: "Employee", last_name: "E", user: user)
  org = FactoryGirl.create :organization, :with_active_plan_year
  @benefit_group = org.employer_profile.plan_years[0].benefit_groups[0]
  bga = FactoryGirl.build :benefit_group_assignment, benefit_group: @benefit_group
  @employee_role = person.employee_roles[0]
  ce =  FactoryGirl.build(:census_employee,
          first_name: person.first_name, 
          last_name: person.last_name, 
          dob: person.dob, 
          ssn: person.ssn, 
          employee_role_id: @employee_role.id,
          employer_profile: org.employer_profile
        )

  ce.benefit_group_assignments << bga
  ce.link_employee_role!
  ce.save!
  @employee_role.update_attributes(census_employee_id: ce.id, employer_profile_id: org.employer_profile.id)
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
  within ".shop-for-plans-widget" do
    click_link "Enroll"
  end
end

Then (/Employee redirects to ivl flow/) do
  expect(page).to have_content("Personal Information")
end
