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

  Scenario: When the broker is hired as a census employee and registration is complete through employee role
    Given a CCA site exists with a benefit market
    # These steps will set up:
    # Given Primary Broker Ricky Martin exists
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

    # Set up employer
    And benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer Acme Inc.
    And renewal employer Acme Inc. has active and renewal enrollment_open benefit applications
    # And Acme Inc. employer has a staff role
    And there is a census employee record and employee role for Ricky Martin for employer Acme Inc.
    And census employee Ricky Martin is a newly_designated_eligible employee
    And this employer Acme Inc. has first_of_month rule

    And employee Ricky Martin already matched with employer Acme Inc. and logged into employee portal
    Then Employee should click on Manage Family button
    Then Employee should click on the Personal Tab link
    Then Employee should not see phone main field in the personal information fields
    And Employee Ricky Martin should only have phone with work kind

