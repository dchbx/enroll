# frozen_string_literal: true

include Config::SiteHelper

When(/^the system date is (greater|less) than the earliest_start_prior_to_effective_on$/) do |compare|
  if compare == 'greater'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.effective_period.min + 5.days))
    TimeKeeper.date_of_record > initial_application.effective_period.min == true
  else
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.effective_period.min - 5.days))
    TimeKeeper.date_of_record < initial_application.effective_period.min == true
  end
end

When(/^the system date is (less) than the monthly_open_enrollment_end_on$/) do |compare|
  TimeKeeper.date_of_record < initial_application.open_enrollment_period.max == true if compare == "less"
end

And(/^the system date is (greater|less) than the publish_due_day_of_month$/) do |compare|
  if compare == 'less'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.last_day_to_publish - 1.day)) unless TimeKeeper.date_of_record < initial_application.last_day_to_publish == true
  elsif compare == 'greater'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.last_day_to_publish + 1.day)) unless TimeKeeper.date_of_record > initial_application.last_day_to_publish == true
  end
end

When(/^the system date is (.*?) open_enrollment_period start date$/) do |compare|
  if compare == 'greater than'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.effective_period.min + 15.days))
    TimeKeeper.date_of_record > initial_application.open_enrollment_period.min == true
  end
end

When(/^the user clicks on Force Publish button$/) do
  page.execute_script("[...document.querySelectorAll('.col-actions .dropdown-menu li a')].filter(e => e.innerText == 'Force Publish')[0].click();")
end

And(/^the user clicks submit to confirm force publish$/) do
  wait_for_ajax
  find('.heading-text', text: 'Publish Application', wait: 10)
  page.find_button('Submit').click
end

Then(/^the force published action should display 'Employer\(s\) Plan Year was successfully published'$/) do
  sleep 2
  expect(page).to have_content('Employer(s) Plan Year was successfully published')
end

When (/^(.*?) FTE count is (less than or equal|more than) to shop:small_market_employee_count_maximum$/) do |_employer, compare|
  if compare == 'less than or equal'
    initial_application.update_attributes(fte_count: fte_max_count - 1)
  elsif compare == 'more than'
    initial_application.update_attributes(fte_count: fte_max_count + 5)
  end
end

And (/^(.*?) primary address state (is|is not) MA$/) do |_employer, compare|
  if compare == 'is'
    initial_application.benefit_sponsorship.profile.primary_office_location.address.update_attributes(state: Settings.aca.state_abbreviation.to_s.downcase) unless initial_application.sponsor_profile.is_primary_office_local?
  elsif compare == 'is not'
    initial_application.benefit_sponsorship.profile.primary_office_location.address.update_attributes(state: '') if initial_application.sponsor_profile.is_primary_office_local?
  end
end

Then (/^a (less than or equal|more than) warning message will appear$/) do |compare|
  if compare == 'less than or equal'
    expect(page).to have_content("Small business NOT located in #{Settings.aca.state_name}")
  elsif compare == 'more than'
    expect(page).to have_content("Small business should have 1 - #{Settings.aca.shop_market.small_market_employee_count_maximum} full time equivalent employees")
  end
end

And(/^ask to confirm intention to publish$/) do
  page.driver.browser.accept_confirm
end

And(/^the user clicks force publish$/) do
  find('a', :text => "Force Publish", wait: 5).click
end

Then(/^the user will see application ineligible message$/) do
  expect(page).to have_content('As submitted, this application is ineligible for coverage')
end

And(/^the user clicks publish anyways$/) do
  find('a', :text => "Publish Anyways", wait: 5).click
end

Then(/^the force publish successful message should be displayed$/) do
  find('h4', text: 'Force Publish Successful', wait: 5)
  expect(page).to have_content('Force Publish Successful')
end

Then(/^the user will see published sucessfully for review message$/) do
  expect(page).to have_content('Employer(s) Plan Year was successfully submitted for review')
end
