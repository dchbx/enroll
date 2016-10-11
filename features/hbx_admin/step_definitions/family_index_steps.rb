Given(/^I click the Families link from the hbx_profiles page$/) do
  # create enrollment that is in both markets
  person_all = FactoryGirl.create(:person, :with_family, :with_consumer_role, :with_employee_role)
  family_all = person_all.primary_family
  FactoryGirl.create(:hbx_profile, :no_open_enrollment_coverage_period, :ivl_2015_benefit_package)
  qle_all = FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
  FactoryGirl.create(:special_enrollment_period, family: family_all, effective_on_kind:"date_of_event", qualifying_life_event_kind_id: qle_all.id)
  all_er_profile = FactoryGirl.create(:employer_profile)
  all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
  person_all.employee_roles.first.census_employee = all_census_ee
  person_all.employee_roles.first.save!
  family_all = Family.find(family_all.id)
  Caches::PlanDetails.load_record_cache!

  visit '/'
  #visit "/exchanges/hbx_profiles/family_index"
  click_link 'HBX Portal'
  click_link 'Families'
end

Then(/^I should see the Family Index page$/) do
  expect(page).to have_content('Families')
end

Then(/^it should have a column with the heading "([^"]*)"$/) do |arg1|
  expect(page).to have_content(arg1)
end
