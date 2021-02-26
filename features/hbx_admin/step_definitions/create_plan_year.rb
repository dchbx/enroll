# frozen_string_literal: true

Given(/^initial employer (.*) has (.*) benefit application with terminated on (.*)$/) do |name, aasm, expected_start_event|
  step "initial employer #{name} has #{aasm} benefit application"

  unless expected_start_event == 'draft_py_effective_on'
    profile = @organization[name].employer_profile

    # Considering the below dates based on draft PY creation date, which is 3rd option from the dropdown of create PY UI
    two_month_advanced_date = TimeKeeper.date_of_record + 2.months
    end_of_the_month = TimeKeeper.date_of_record.end_of_month - 1.day

    benefit_application = profile.benefit_sponsorships.first.benefit_applications.where(aasm_state: :termination_pending).first
    start_on = TimeKeeper.date_of_record - 4.months
    end_on = expected_start_event == 'draft_py_date_lt_term_on' ? two_month_advanced_date : end_of_the_month
    benefit_application.update_attributes(effective_period: start_on..end_on)
  end
end

And(/^Hbx Admin should see the list of employer accounts and an Action button$/) do
  within('.effective-datatable') do
    expect(page).to have_css('.dropdown-toggle', count: 2)
  end
end

And(/^update rating area$/) do
  renewal_rating_area
  benefit_sponsorship.update_attributes!(rating_area_id: rating_area.id)
end

Given('the user has clicked the Create Plan Year button') do
  find('.btn',text: 'Create Plan Year').click
end

Given('the user has a valid input for all required fields') do
  find('#baStartDate > option:nth-child(2)').click
  find('#fteCount').fill_in :with => '20'
  find('label',:text => 'Open Enrollment End Date').click
end

When(/the admin clicks (.*)$/) do |btn|
  find('.btn', :text => btn).click
end

Then(/the user will see a (.*) message/) do |message|
  expect(page).to have_content(message)
end

Then('the draft application will be created') do
  expect(page).to have_content('Plan Year (Draft)')
end

Then(/the existing applications for ABC Widgets will be (.*)$/) do |state|
  expect(page).to have_content("Plan Year (#{state})")
end

Then('the user will see a pop up modal with "Confirm" or "Cancel" action') do
  expect(page).to have_content('Confirm Create Plan Year')
end

Then('the draft application will NOT be created') do
  expect(page).to_not have_content('Plan Year (Draft)')
end
