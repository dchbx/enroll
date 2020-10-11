@wip
# Is fake fein attribute doesn't exist in new model
# look at app/helpers/broker_agencies/profiles_helper.rb

Feature: Fake FEINs
  Broker creates a Broker Agency with FAKE Fein
  And I select the all security question and give the answer
  When I have submitted the security questions
  The Broker should not see Fake FEIN in his account
  The Hbx Admin should be able to see the Fake FEIN in broker's account
  Brokers with REAL Feins should Fein in their account

Scenario: Primary Broker should not see FAKE Fein in his account
  Given a CCA site exists with a benefit market
  And there is an employer ABC Widgets
  Given There are preloaded security question on the system
  When Primary Broker visits the HBX Broker Registration form
  Given a valid ach record exists
  Given Primary Broker has not signed up as an HBX user
  Then Primary Broker should see the New Broker Agency form
  When Primary Broker enters personal information
  And Current broker agency is fake fein
  And Primary Broker enters broker agency information for SHOP markets
  And Primary Broker enters office location for default_office_location
  And Primary Broker clicks on Create Broker Agency
  Then Primary Broker should see broker registration successful message
  
  Given Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  When user fills out the security questions modal
  When I have submitted the security questions
  And Hbx Admin clicks on Brokers 
  And Hbx Admin clicks on Broker Applications 
  Then Hbx Admin should see the list of broker applicants
  When Hbx Admin click the current broker applicant show button
  Then Hbx Admin should see the broker application with carrier appointments
  And Hbx Admin click approve broker button
  Then Hbx Admin should see the broker successfully approved message
  And Hbx Admin logs out

  Then Primary Broker should receive an invitation email
  When Primary Broker visits invitation url in email
  Then Primary Broker should see the create account page
  When Primary Broker registers with valid information
  When user fills out the security questions modal
  When I have submitted the security questions
  Then Primary Broker should see successful message with broker agency home page
  Then Primary Broker should not see fein
  And Primary Broker logs out

Scenario: Hbx Admin should see broker's actual FEIN
  Given Hbx Admin exists
  Given There are preloaded security question on the system

  And a broker exists
  When Hbx Admin logs on to the Hbx Portal
  When user fills out the security questions modal
  When I have submitted the security questions
  And Hbx Admin clicks on Brokers
  And Hbx Admin clicks on Broker Applications
  When he enters an broker agency name and clicks on the search button
  Then he should see the one result with the agency name
  And Hbx Admin clicks on the broker
  Then Hbx Admin should see fein
  And Hbx Admin logs out

Scenario: Hbx Admin should see fake fein in broker's account
  Given a CCA site exists with a benefit market
  Given There are preloaded security question on the system

  And there is an employer ABC Widgets
  When Primary Broker visits the HBX Broker Registration form
  Given a valid ach record exists
  Given Primary Broker has not signed up as an HBX user
  Then Primary Broker should see the New Broker Agency form
  When Primary Broker enters personal information
  And Primary Broker enters broker agency information for SHOP markets
  And Primary Broker enters office location for default_office_location
  And Primary Broker clicks on Create Broker Agency

  Then Primary Broker should see broker registration successful message

  Given Hbx Admin exists
  When Hbx Admin logs on to the Hbx Portal
  When user fills out the security questions modal
  When I have submitted the security questions
  And Hbx Admin clicks on Brokers
  And Hbx Admin clicks on Broker Applications
  Then Hbx Admin should see the list of broker applicants
  When Hbx Admin click the current broker applicant show button
  Then Hbx Admin should see the broker application with carrier appointments
  And Hbx Admin click approve broker button
  Then Hbx Admin should see the broker successfully approved message
  And Hbx Admin logs out

  Then Primary Broker should receive an invitation email
  When Primary Broker visits invitation url in email
  Then Primary Broker should see the create account page
  When Primary Broker registers with valid information
  When user fills out the security questions modal
  When I have submitted the security questions
  Then Primary Broker should see successful message with broker agency home page
  Then Primary Broker should not see fein
  And Primary Broker logs out

  When Hbx Admin logs on to the Hbx Portal
  And Hbx Admin clicks on Brokers
  And Hbx Admin clicks on Broker Applications
  And Hbx Admin clicks on the Fake broker
  Then Hbx Admin should see fein
  And Hbx Admin logs out
