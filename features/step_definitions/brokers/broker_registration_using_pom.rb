When("Primary Broker visits the HBX Broker Registration form POM") do
  visit '/'
  find(".broker-registration", wait: 10).click
end
  
Then("Primary Broker should see the New Broker Agency form POM") do
  find(BrokerRegistration.broker_registration_form, wait: 10)
  expect(page).to have_xpath(BrokerRegistration.broker_registration_form)
  expect(page).to have_content(BrokerRegistration.broker_agency_inf_text)
end
  
  When("Primary Broker enters personal information POM") do
  visit "/broker_registration"
  fill_in BrokerRegistration.first_name, with: "This Is" 
  fill_in BrokerRegistration.last_name,	with: "a POM example"
  fill_in BrokerRegistration.broker_dob, with: "12/12/1876" 
  fill_in BrokerRegistration.npn, with: "837364667" 
end

