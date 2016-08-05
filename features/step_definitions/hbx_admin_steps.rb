

Given(/^I click the SEP link from the Admin DC Health Link login page$/) do
  # load the system with an instance of All. The admin portal by default goes to the All
  # tab and needs to have at least a single entry there in order for cucumber to not fail
  # when the view calls the fam.each do |f| method

  #create All person
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

  #create IVL only person
  #person_ivl = FactoryGirl.create(:person, :with_family, :with_consumer_role)
  #family_ivl = person_ivl.primary_family
  #qle_ivl = FactoryGirl.create(:qualifying_life_event_kind, market_kind: "individual")
  #FactoryGirl.create(:special_enrollment_period, family: family_ivl, effective_on_kind:"date_of_event", qualifying_life_event_kind_id: qle_ivl.id)
  #family_ivl = Family.find(family_ivl.id)

  #create EE only person
  #person_ee = FactoryGirl.create(:person, :with_family, :with_employee_role)
  #family_ee = person_ee.primary_family
  #qle_ee = FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
  #FactoryGirl.create(:special_enrollment_period, family: family_ee, effective_on_kind:"date_of_event", qualifying_life_event_kind_id: qle_ee.id)
  #ee_er_profile = FactoryGirl.create(:employer_profile)
  #ee_census_ee = FactoryGirl.create(:census_employee, employer_profile: ee_er_profile)
  #person_ee.employee_roles.first.census_employee = ee_census_ee
  #person_ee.employee_roles.first.save!
  #family_ee = Family.find(family_ee.id)

  Caches::PlanDetails.load_record_cache!
  #binding.pry
  sleep 2
  visit "/"
  click_link 'HBX Portal'
  click_link 'SEP'
end

Then(/^the SEP page is displayed$/) do
  expect(page).to have_content('SEP Dashboard')
end

Then(/^a search box is displayed where I can search by name or ssn$/) do
  expect(page).to have_content('Search')
end

Then(/^the ALL, IVL and EE tabs appear above the display list$/) do
  expect(page).to have_content('All')
  expect(page).to have_content('IVL')
  expect(page).to have_content('EE')
end

Then(/^I see columns with headings HBX ID, Last Name, First Name, SSN, Consumer and Employee$/) do
  expect(page).to have_content('HBX ID')

  expect(page).to have_content('Last Name')

  expect(page).to have_content('First Name')
  expect(page).to have_content('SSN')
  expect(page).to have_content('Consumer?')
  expect(page).to have_content('Employee?')

end

Then(/^I see the Add SEP and History buttons$/) do
  expect(page).to have_content('SEP HISTORY')
  #find('.nav-tabs').find('a', :text => "All").click
  #wait_for_ajax
  #screenshot("All Tab Display")
  #find('.nav-tabs').find('a', :text => "IVL").click
  #wait_for_ajax
  #screenshot("IVL Tab Display")
  #find('.nav-tabs').find('a', :text => "EE").click
  #wait_for_ajax
  #screenshot("EE Tab Display")
  #page.has_button?("SEP HISTORY")
end

Given(/^I have a primary subscriber who is registered only as a consumer$/) do
  person_ivl = FactoryGirl.create(:person, :with_family, :with_consumer_role)
  family_ivl = person_ivl.primary_family
  qle_ivl = FactoryGirl.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryGirl.create(:special_enrollment_period, family: family_ivl, effective_on_kind:"date_of_event", qualifying_life_event_kind_id: qle_ivl.id)
  family_ivl = Family.find(family_ivl.id)

end

When(/^I click the IVL tab$/) do
  find('.nav-tabs').find('a', :text => "IVL").click
  wait_for_ajax
  screenshot("IVL Tab Display")
end

Then(/^I see Yes in the Consumer Field and No in the Employee field for his search results$/) do
  screenshot("IVL results")
  expect(page).to have_content('Yes')
  expect(page).to have_content('No')
end

Given(/^I have a primary subscriber who is only registered as an employee$/) do
  person_ee = FactoryGirl.create(:person, :with_family, :with_employee_role)
  family_ee = person_ee.primary_family
  qle_ee = FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
  FactoryGirl.create(:special_enrollment_period, family: family_ee, effective_on_kind:"date_of_event", qualifying_life_event_kind_id: qle_ee.id)
  ee_er_profile = FactoryGirl.create(:employer_profile)
  ee_census_ee = FactoryGirl.create(:census_employee, employer_profile: ee_er_profile)
  person_ee.employee_roles.first.census_employee = ee_census_ee
  person_ee.employee_roles.first.save!
  family_ee = Family.find(family_ee.id)
end

Then(/^I see No in the Consumer Field and Yes in the Employee field for his search results$/) do
  expect(page).to have_content('Yes')
  expect(page).to have_content('No')
end

Given(/^I have a primary subscriber who is registered as a consumer and as an employee$/) do
  #already created instnace of this subscriber in previous step
  person_both = FactoryGirl.create(:person, :with_family, :with_consumer_role, :with_employee_role)
  family_both = person_both.primary_family
  FactoryGirl.create(:hbx_profile, :no_open_enrollment_coverage_period, :ivl_2015_benefit_package)
  qle_both = FactoryGirl.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryGirl.create(:special_enrollment_period, family: family_both, effective_on_kind:"date_of_event", qualifying_life_event_kind_id: qle_both.id)
  both_er_profile = FactoryGirl.create(:employer_profile)
  both_census_ee = FactoryGirl.create(:census_employee, employer_profile: both_er_profile)
  person_both.employee_roles.first.census_employee = both_census_ee
  person_both.employee_roles.first.save!
  family_both = Family.find(family_both.id)
end



Then(/^I see Yes in the Consumer Field and Yes in the Employee field for his search results$/) do
  expect(page).to have_content('Yes')
  expect(page).not_to have_content('No')
end

Given(/^there are (\d+) consumer only subscribers, (\d+) employee only subscribers and (\d+) both subscribers in the system$/) do |arg1, arg2, arg3|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see (\d+) consumers only,  (\d+) employees only and (\d+) both subscribers$/) do |arg1, arg2, arg3|
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^I click the EE tab$/) do
  find('.nav-tabs').find('a', :text => "EE").click
  wait_for_ajax
  screenshot("EE Tab Display")
end

When(/^I click the All tab$/) do
  find('.nav-tabs').find('a', :text => "All").click
  wait_for_ajax
  screenshot("All Tab Display")
end

When(/^I click on the Add SEP button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following IVL\/EE Radio button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following SEP Reason dropdown$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following Effective Date Rule dropdown$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following CSL\#$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following comment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following submit button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following SEP start Date$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following SEP end Date for IVL$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following SEP end Datre for EE$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following Next Possible Effective Date$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the SEP add page is displayed with the following Choice Date (\d+)$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^Event date is enabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^SEP Start is enabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^SEP End is enabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^Effective dates is enabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^Event date is disabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^SEP Start is disabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^SEP End is disabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^Effective dates is disabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^I have entered Choice Date (\d+)$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^a consumer naviagtes to plan shopping$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the SEP is still open$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^an effective drop\-down is displayed$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^contains the effective date and any choice dates entered by the HBX\-admin$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the consumer selects the effective date$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^then selects the Choice date$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the choice date is the one that will be applied to the consumer$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^John Smith is registered as IVL$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see the SEP history for him in chronological order \#newest to oldest$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see SEP reason dropdown$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see Effective Date Rule$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see Event Date$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see SEP Start Date$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see SEP End Date$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see Next Possible Effective Date$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see Choice Date (\d+)$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see CSL\#$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see medical plan select and effective dates$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see dental plan select and effective dates$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see comments$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^Jan Doe is registered as EE$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^Mark Jones is registered as All$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^I click the history button$/) do
  find('a', :text => "SEP HISTORY").click
end

Then(/^I see the Back button$/) do
  expect(page).to have_content('BACK')
end
