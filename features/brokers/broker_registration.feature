Feature: Broker Agency Registration

  Scenario: Primary Broker has not signed up on the HBX
    Given a CCA site exists with a benefit market
    When Primary Broker visits the HBX Broker Registration form
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form
    When Primary Broker enters personal information
    And And Primary Broker enters broker agency information for SHOP markets
    And Primary Broker enters office location for default_office_location
    Then Primary Broker should see broker registration successful message

    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin is on Broker Index of the Admin Dashboard
    Then Hbx Admin is on Broker Index and clicks Broker Applicants
    When Hbx Admin clicks on the current broker applicant show button
    Then Hbx Admin should see the broker application with carrier appointments
    When Hbx Admin click approve broker button
    Then Hbx Admin should see the broker successfully approved message
    And Hbx Admin logs out

    Then Primary Broker should receive an invitation email
    When Primary Broker visits invitation url in email
    Then Primary Broker should see the create account page
    When Primary Broker registers with valid information
    Then they should see a welcome message
    And Primary Broker logs out
