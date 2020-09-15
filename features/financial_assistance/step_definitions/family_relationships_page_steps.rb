# frozen_string_literal: true

Given(/^at least two other household members exist$/) do
  click_link "Add New Person"

  fill_in 'applicant[first_name]', :with => 'johnson'
  fill_in 'applicant[last_name]', :with => 'smith'
  fill_in 'jq_datepicker_ignore_applicant[dob]', :with => '10/10/1984'
  #click_link(10)
  click_outside_datepicker('Household Info: Family Members')
  fill_in 'applicant[ssn]', :with => '123456543'
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Spouse')]").click
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  choose('radio_incarcerated_no', allow_label_click: true)
  choose('indian_tribe_member_no', allow_label_click: true)
  choose('applicant_us_citizen_true', allow_label_click: true)
  choose('applicant_naturalized_citizen_false', allow_label_click: true)
  find(".btn", text: "CONFIRM MEMBER").click

  click_link "Add New Person"
  fill_in 'applicant[first_name]', :with => 'smity'
  fill_in 'applicant[last_name]', :with => 'johnson'
  fill_in 'jq_datepicker_ignore_applicant[dob]', :with => '10/10/2010'
  #click_link(10)
  click_outside_datepicker('Household Info: Family Members')
  fill_in 'applicant[ssn]', :with => '123456549'
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Child')]").click
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  choose('radio_incarcerated_no', allow_label_click: true)
  choose('indian_tribe_member_no', allow_label_click: true)
  choose('applicant_us_citizen_true', allow_label_click: true)
  choose('applicant_naturalized_citizen_false', allow_label_click: true)
  find(".btn", text: "CONFIRM MEMBER").click

  sleep 1

  expect(page).to have_content('ADD INCOME & COVERAGE INFO', count: 3)
end

Given(/^that the user is on the FAA Family Relationships page$/) do
  page.should have_xpath('//*[@id="family-matrix"]/h1')
end


Then(/^View My Applications left section WILL display$/) do
  expect(page).to have_content('View My Applications')
end

Then(/^Review & Submit left section WILL display$/) do
  expect(page).to have_content('Review & Submit')
end

Given(/^there is a nil value for at least one relationship$/) do
  expect(find_all(:css, ".selectric .label").map{ |selector| selector.text }).to include("choose")
end

Then(/^the family member row will be highlighted$/) do
  expect(page).to have_css('.missing_relation')
end


When(/^the user populates the drop down with a value$/) do
  @relationship = find_all(:css, ".missing_relation").first
  @relationship.find("span", :text => "choose").click
  @relationship.find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Parent')]").click
end


Then(/^the relationship is saved$/) do
  begin
    expect(@relationship.find(:css, ".selectric .label").text).to eq("Parent")
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    sleep 10
    expect(@relationship.find(:css, ".selectric .label").text).to eq("Parent")
  end
end

And(/^all the relationships have been entered$/) do
  find('.interaction-click-control-continue').click
  expect(page).to have_no_css('.missing_relation')
  sleep 3
end

Then(/^the user will navigate to the Review & Submit page$/) do
  expect(page).to have_content("Review Your Application")
end