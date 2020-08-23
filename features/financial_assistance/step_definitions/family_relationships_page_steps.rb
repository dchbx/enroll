# frozen_string_literal: true

Given(/^the user is logged in$/) do
  login_as user :with_consumer_role
end

And(/^family has two other household members$/) do
  FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)

  family = user.person.primary_family
  family.family_members << FactoryBot.build(:family_member, family: family, is_primary_applicant: false, is_active: true, person: FactoryBot.create(:person, first_name: "John", last_name: "Doe"))
  family.family_members << FactoryBot.build(:family_member, family: family, is_primary_applicant: false, is_active: true, person:  FactoryBot.create(:person, first_name: "Alex", last_name: "Doe"))
  family.family_members.each(&:save!)
  primary_person = family.primary_applicant.person
  # one relationship left out for later steps
  dependents = family.dependents.map{|fm| fm.person}
  dependents[0].ensure_relationship_with(dependents[1], 'sibling', family.id)
  dependents[0].ensure_relationship_with(primary_person, 'parent', family.id)
  primary_person.ensure_relationship_with(dependents[0], 'child', family.id)
  dependents[1].ensure_relationship_with(dependents[0], 'sibling', family.id)
  primary_person.ensure_relationship_with(dependents[1], 'child', family.id)
  primary_person.save
  family.households.first.add_household_coverage_member(family.family_members.first)
  family.save
  family.applications << application
  application.save!
end

Then(/^the user navigates to Family Relationships page$/) do
  visit insured_family_relationships_path(user.person.consumer_role.id)
end

Given(/^that the user is on the FAA Family Relationships page$/) do
  expect(page).to have_content("Household Relationships")
end

Then(/^Family Relationships WILL display in the left nav$/) do
  expect(find('.interaction-click-control-household-info').text).to eq('Household Info')
end

Then(/^View My Applications left section WILL display$/) do
  expect(page).to have_content('View My Applications')
end

Then(/^Review & Submit left section WILL display$/) do
  expect(page).to have_content('Review & Submit')
end

Given(/^there is a nil value for at least one relationship$/) do
  expect(find_all(:css, ".selectric .label").map{ |selector| selector.text }).to include("")
end

Then(/^the family member row will be highlighted$/) do
  expect(page).to have_css('.missing_relation')
end


When(/^the user populates the drop down with a value$/) do
  find('.button').click
  @relationship = find(".selectric-items").find(:xpath, 'div/ul/li[5]').click
end


Then(/^the relationship is saved$/) do
  expect(find(".selectric-wrapper").find(:xpath, 'div[2]/span').text).to eq("parent")
  click_button("Add Relationship")
end

Given(/^all the relationships have been entered$/) do
  find_all(:css, ".missing_relation").each do |relation|
    relation.find(:xpath, 'div/div[2]/div[2]/div[2]/div/div[3]/div/ul/li[7]', :visible => false).trigger('click')
  end
  find_all(:css, ".selectric .label").each do |selector|
    expect(selector.text).to eq("parent")
  end
  expect(page).to have_no_css('.missing_relation')
end

Then(/^the user will navigate to the Review & Submit page$/) do
  expect(page).to have_content("Review Your Application")
end
