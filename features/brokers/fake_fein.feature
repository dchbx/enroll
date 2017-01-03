Feature: Fake FEINs
  Broker creates a Broker Agency with FAKE Fein
  The Broker should not see Fake FEIN in his account
  The Hbx Admin should be able to see the Fake FEIN in broker's account
  Brokers with REAL Feins should Fein in their account
  
Scenario: Primary Broker should not see FAKE Fein in his account
  When Primary Broker visits the HBX Broker Registration form

  Given Primary Broker has not signed up as an HBX user
  Then Primary Broker should see the New Broker Agency form
  When Primary Broker enters personal information
  And Primary Broker enters broker agency information
  And Primary Broker enters office location for default_office_location
  And Primary Broker clicks on Create Broker Agency
  Then Primary Broker should see broker registration successful message

  Given Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And Hbx Admin clicks on the Brokers tab
  Then Hbx Admin should see the list of broker applicants
  When Hbx Admin clicks on the current broker applicant show button
  Then Hbx Admin should see the broker application
  When Hbx Admin clicks on approve broker button
  Then Hbx Admin should see the broker successfully approved message
  And Hbx Admin logs out

  Then Primary Broker should receive an invitation email
  When Primary Broker visits invitation url in email
  Then Primary Broker should see the create account page
  When Primary Broker registers with valid information
  Then Primary Broker should see successful message with broker agency home page
  Then Primary Broker should not see fein
  And Primary Broker logs out

Scenario: Hbx Admin should see broker's actual FEIN
  Given Hbx Admin exists
  And a broker exists
  When Hbx Admin logs on to the Hbx Portal
  And Hbx Admin should click on the Broker Agencies tab
  And Hbx Admin clicks on the broker
  Then Hbx Admin should see fein
  And Hbx Admin logs out

Scenario: Hbx Admin should see fake fein in broker's account
  When Primary Broker visits the HBX Broker Registration form
  Given Primary Broker has not signed up as an HBX user
  Then Primary Broker should see the New Broker Agency form
  When Primary Broker enters personal information
  And Primary Broker enters broker agency information
  And Primary Broker enters office location for default_office_location
  And Primary Broker clicks on Create Broker Agency
  Then Primary Broker should see broker registration successful message

  Given Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  And Hbx Admin clicks on the Brokers tab
  Then Hbx Admin should see the list of broker applicants
  When Hbx Admin clicks on the current broker applicant show button
  Then Hbx Admin should see the broker application
  When Hbx Admin clicks on approve broker button
  Then Hbx Admin should see the broker successfully approved message
  And Hbx Admin logs out

  Then Primary Broker should receive an invitation email
  When Primary Broker visits invitation url in email
  Then Primary Broker should see the create account page
  When Primary Broker registers with valid information
  Then Primary Broker should see successful message with broker agency home page
  Then Primary Broker should not see fein
  And Primary Broker logs out

  When Hbx Admin logs on to the Hbx Portal
  And Hbx Admin should click on the Broker Agencies tab
  And Hbx Admin clicks on the Fake broker
  Then Hbx Admin should see fein
  And Hbx Admin logs out