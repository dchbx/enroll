# frozen_string_literal: true

When(/a Primary Broker visits the HBX Broker Registration form POM/) do
  visit '/'
  find(HomePage.broker_registration_btn, wait: 10).click
end

Then(/Primary Broker should see the New Broker Agency form POM/) do
  expect(page).to have_css(BrokerRegistration.broker_registration_form)
end

When(/Primary Broker enters personal information POM/) do
  fill_in BrokerRegistration.first_name, with: 'This is a POM'
  fill_in BrokerRegistration.last_name, with: 'example'
  fill_in BrokerRegistration.broker_dob, with: '02/02/1989'
  fill_in BrokerRegistration.email, with: 'pomexample@gmail.com'
  fill_in BrokerRegistration.npn, with: '124534256'
end

And(/Primary Broker enters broker agency information POM/) do
  fill_in BrokerRegistration.legal_name, with: "Broker test pom"
  fill_in BrokerRegistration.dba, with: "Broker test"
  select "Individual & Family Marketplace ONLY", from: BrokerRegistration.practice_area_dropdown
  select "English", from: BrokerRegistration.select_languages
  find(BrokerRegistration.accept_new_client_checkbox).click
  fill_in BrokerRegistration.address, with: "123 test"
  select "Primary", from: BrokerRegistration.kind_dropdown
  fill_in BrokerRegistration.city, with: "Washington"
  select "DC", from: BrokerRegistration.state_dropdown
  fill_in BrokerRegistration.zip, with: "20001"
  fill_in BrokerRegistration.area_code, with: "202"
  fill_in BrokerRegistration.number, with: "2678765"
  find(BrokerRegistration.create_broker_agency_btn).click
end

Then(/Primary Broker should see the registration submitted successful message/) do
  sleep 10
  expect(page).to have_content(BrokerRegistration.registration_submitted_succesful_message)
end