
When(/^the user has a family with e_case_id and visit personal information edit page$/) do
  person = FactoryBot.create(:person, first_name: "sarah")
  person2 = FactoryBot.create(:person, :with_consumer_role, first_name: "mahesh")
  family = FactoryBot.create(:family, :with_primary_family_member, person: person2, e_case_id: "e_case_id")
  current_user = FactoryBot.create(:user, :hbx_staff, person: person)
  expect(person2.primary_family.e_case_id).to eq("e_case_id")
  visit edit_insured_consumer_role_path(person2.consumer_role.id)
end

When(/^the applicant with no e_case_id and visit personal information edit page$/) do
  allow_any_instance_of(ConsumerRolePolicy).to receive(:can_view_application_types?).and_return(true)
end

Then(/^EA will automatically populate the Application Type as CURAM$/) do
  expect(page).to have_content("Curam")
  find("span", :text => "Curam").click
end

Then(/^EA will display all the Application Types$/) do
  find("span", :text => "choose").click
  find("li", :text => "Phone")
  find("li", :text => "In Person")
  find("li", :text => "Paper")
  find("li", :text => "Curam")
  find("li", :text => "Mobile")
end

When(/^the Admin selects the Curam application option$/) do
  find("li", :text => "Curam").click
end

Then(/^the Admin should navigate to Household Info Page$/) do
  expect(page).to have_content("#{l10n('family_information')}")
end

When(/^the Admin selects the Mobile application option$/) do
  find("li", :text => "Mobile").click
end
