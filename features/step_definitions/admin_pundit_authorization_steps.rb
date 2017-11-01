Then(/^ the Hbx Admin should see the list of primary applicants and an Action button$/) do
  find_button('Actions').visible?
end

When(/^the Hbx Admin clicks on the Action button$/) do
  find(:xpath, "//*[@id='dropdownMenu1']", :wait => 10).trigger("click")
end

Then(/^the Add SEP option should be enabled$/) do
  # Commenting the line below because we are temporaily disabling the 'Add SEP' link.
  #find_link('Add SEP')['data-remote'].should == 'true'
end

Then(/^the Add SEP option should be disabled$/) do
  find_link('Add SEP')['disabled'].should == 'disabled'
end

Then(/^the Cancel Enrollment option should be enabled$/) do
  find_link('Cancel Enrollment')['data-remote'].should == 'true'
end

Then(/^the Terminate Enrollment option should be enabled$/) do
  find_link('Terminate Enrollment')['data-remote'].should == 'true'
end

Then(/^the Cancel Enrollment option should be disabled$/) do
  find_link('Cancel Enrollment')['disabled'].should == 'disabled'
end

Then(/^the Terminate Enrollment option should be disabled$/) do
  find_link('Terminate Enrollment')['disabled'].should == 'disabled'
end

#Note this step will be used in the future when APTC is completed
Then(/^the Edit APTC\/CSR option should be enabled$/) do
  find_link('Edit APTC / CSR')['data-remote'].should == 'true'
end

#Note this step will be used in the future when APTC is completed
Then(/^the Edit APTC\/CSR option should be disabled$/) do
  find_link('Edit APTC / CSR')['disabled'].should == 'disabled'
end
