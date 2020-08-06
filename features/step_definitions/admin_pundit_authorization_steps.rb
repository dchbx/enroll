# frozen_string_literal: true

Then(/^ the Hbx Admin should see the list of primary applicants and an Action button$/) do
  find_button('Actions').visible?
end

When(/^the Hbx Admin clicks on the Action button$/) do
  find_button('Actions').click
end

Then(/^the Add SEP option should be enabled$/) do
  find_link('Add SEP')['data-remote'].should == 'true'
end

Then(/^the Add SEP option should be disabled$/) do
  find_link('Add SEP')[:disabled] == 'true'
end

Then(/^the Cancel Enrollment option should be enabled$/) do
  find_link('Cancel Enrollment')['data-remote'].should == 'true'
end

Then(/^the Terminate Enrollment option should be enabled$/) do
  find_link('Terminate Enrollment')['data-remote'].should == 'true'
  sleep 5
end

Then(/^the Cancel Enrollment option should be disabled$/) do
  find_link('Cancel Enrollmen')[:disabled] == 'true'
end

Then(/^the Terminate Enrollment option should be disabled$/) do
  find_link('Terminate Enrollment')[:disabled] == 'true'
end

#Note this step will be used in the future when APTC is completed
Then(%r{^the Edit APTC/CSR option should be enabled$}) do
  find_link('Edit APTC / CSR')['data-remote'].should == 'true'
end

#Note this step will be used in the future when APTC is completed
Then(%r{^the Edit APTC/CSR option should be disabled$}) do
  find_link('Edit APTC / CSR').should be_disabled
end
