Feature: Create General Agency and General Agency Staff Role

  Scenario: A General Agency Submits Application
    Given a CCA site exists with a benefit market
    Given a general agency agent visits the DCHBX
    When they click the 'New General Agency' button
    Then they should see the new general agency form
    When they complete the new general agency form and hit the 'Submit' button
    Then they should see a confirmation message
    And a pending approval status

  Scenario: A General Agency is Approved
    Given a CCA site exists with a benefit market
    When that a user with a HBX staff role with HBX Staff subrole exists and is logged in
    And a general agency, pending approval, exists
    And Hbx Admin is on Broker Index of the Admin Dashboard
    And Hbx Admin is on Broker Index and clicks General Agencies
    Then they should see the pending general agency
    When they click the link of general agency
    Then they should see the home of general agency
    When they visit the list of staff
    Then they should see the name of staff
    When they approve the general agency
    Then they should see updated status
    And the general agency should receive an email

  Scenario: A General Agency Creates an Account
    Given a CCA site exists with a benefit market
    Given a general agency, approved, awaiting account creation, exists
    When the HBX admin visits the link received in the approval email
    Then they should see an account creation form
    When they complete the account creation form and hit the 'Submit' button
    Then they should see a welcome message
    And they see the General Agency homepage
    And General Agency Staff logs out

  @broken
  Scenario: Broker creates an account and assigns general agency
    When CareFirst Broker visits the HBX Broker Registration form
    Given CareFirst Broker has not signed up as an HBX user
    Then CareFirst Broker should see the New Broker Agency form
    When CareFirst Broker enters personal information for ga flow
    And CareFirst Broker enters broker agency information for ga flow
    And CareFirst Broker enters office location for default_office_location
    And CareFirst Broker clicks on Create Broker Agency
    Then CareFirst Broker should see broker registration successful message

    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin clicks on the Brokers tab
    Then Hbx Admin should see the list of broker applicants
    When Hbx Admin clicks on the current broker applicant show button
    Then Hbx Admin should see the broker application with carrier appointments
    When Hbx Admin clicks on approve broker button
    Then Hbx Admin should see the broker successfully approved message
    And Hbx Admin logs out


    Then CareFirst Broker should receive an invitation email for ga flow
    When CareFirst Broker visits invitation url in email
    Then CareFirst Broker should see the create account page
    When CareFirst Broker registers with valid information for ga flow
    Then CareFirst Broker should see successful message with broker agency home page for ga flow
    And CareFirst Broker logs out

    Given Employer has not signed up as an HBX user
    When I visit the Employer portal
    Then John Wood creates an HBX account
    Then John Wood should see a successful sign up message
    Then I should click on employer portal
    And John Wood creates a new employer profile with default_office_location
    When Employer clicks on the Brokers tab
    Then Employer should see no active broker
    When Employer click on Browse Brokers button
    Then Employer should see broker agencies index view
    Then Employer should see broker agency of CareFirst
    When Employer clicks select broker button
    Then Employer should see confirm modal dialog box
    When Employer confirms broker selection
    Then Employer should see broker selected successful message
    And Employer logs out

    Then CareFirst Broker logs on to the Broker Agency Portal
    Then CareFirst Broker should see the page of Broker Agency
    And CareFirst Broker clicks on the Employers tab
    Then CareFirst Broker should see list of employers and assign portal
    When CareFirst Broker assign employer to general agency
    Then CareFirst Broker should see assign successful message
    And CareFirst Broker clicks on the Employers tab
    Then CareFirst Broker should see the assigned general agency
    And CareFirst log out

    When General Agency staff logs on the General Agency Portal
    Then General Agency should see general agency home page
    When General Agency clicks on the link of employers
    Then General Agency should see the list of employer
    And General Agency log out
