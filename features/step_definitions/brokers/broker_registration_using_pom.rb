When("Primary Broker visits the HBX Broker Registration form POM") do
  visit '/'
  find(".broker-registration", wait: 10).click
end
  
Then("Primary Broker should see the New Broker Agency form POM") do
  broker_registration_pom = BrokerRegistration.new
  broker_registration_pom.broker_registration_form
  expect(page).to have_xpath(broker_registration_pom.broker_registration_form)
  expect(page).to have_content("Broker Agency Information")
end
  
When("Primary Broker enters personal information POM") do
  broker_registration_pom = BrokerRegistration.new
  visit "/broker_registration"
  fill_in broker_registration_pom.first_name, with: 'This Is' 
  fill_in broker_registration_pom.last_name,	with: 'a POM example'
  fill_in broker_registration_pom.broker_dob, with: "12/12/1992"
  fill_in broker_registration_pom.email, with: 'POMexample@gmail.com' 
  fill_in broker_registration_pom.npn, with: '837364667' 
end