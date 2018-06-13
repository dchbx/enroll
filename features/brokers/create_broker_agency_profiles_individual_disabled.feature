@individual_enabled
Feature: Create Primary Broker and Broker Agency
  In order for Brokers to help SHOP employees only
  The Primary Broker must create and manage an account on the HBX for their organization.
  Such organizations are referred to as a Broker Agency
  The Primary Broker should be able to create a Broker Agency account application
  The HBX Admin should be able to approve the application and send an email invite
  The Primary Broker should receive the invite and create an Account
  The Employer should be able to select the Primary Broker as their Broker
  The Broker should be able to manage that Employer
  The Broker should be able to select a family covered by that Employer
  The Broker should be able to purchase insurance for that family

  @more_than_sole_source
  Scenario: Primary Broker has not signed up on the HBX
    When Primary Broker visits the HBX Broker Registration form

    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form
    When Primary Broker enters personal information
    And Primary Broker enters broker agency information for SHOP markets
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
    And Primary Broker logs out

    Given Employer has not signed up as an HBX user
    When I visit the Employer portal
    Then Tim Wood creates an HBX account
    Then Tim Wood should see a successful sign up message
    Then I should click on employer portal
    And Tim Wood creates a new employer profile with default_office_location
    When Employer clicks on the Brokers tab
    Then Employer should see no active broker
    When Employer click on Browse Brokers button
    Then Employer should see broker agencies index view
    # When Employer searches broker agency by name
    Then Employer should see broker agency
    When Employer clicks select broker button
    Then Employer should see confirm modal dialog box
    When Employer confirms broker selection
    Then Employer should see broker selected successful message
    When Employer clicks on the Brokers tab
    Then Employer should see broker active for the employer
    When Employer terminates broker
    Then Employer should see broker terminated message
    When Employer clicks on the Brokers tab
    Then Employer should see no active broker
    When Employer clicks on Browse Brokers button
    Then Employer should see broker agencies index view
    # When Employer searches broker agency by name
    Then Employer should see broker agency
    When Employer clicks select broker button
    Then Employer should see confirm modal dialog box
    When Employer confirms broker selection
    Then Employer should see broker selected successful message
    And Employer logs out

    Then Primary Broker logs on to the Broker Agency Portal
    And Primary Broker clicks on the Employers tab
    Then Primary Broker should see Employer and click on legal name
    Then Primary Broker should see the Employer Profile page as Broker
    When Primary Broker creates and publishes a plan year
    Then Primary Broker should see a published success message without employee
    When Primary Broker clicks on the Employees tab
    Then Primary Broker clicks to add the first employee
    Then Primary Broker creates Broker Assisted as a roster employee
    Then Primary Broker sees employer census family created
    And I log out

    When I go to the employee account creation page
    When Broker Assisted creates an HBX account
    #Then Broker Assisted should be logged on as an unlinked employee
    When Broker Assisted goes to register as an employee
    Then Broker Assisted should see the employee search page
    When Broker Assisted enter the identifying info of Broker Assisted
    Then Broker Assisted should see the matched employee record form
    When Broker Assisted accepts the matched employer
    Then Broker Assisted completes the matched employee form for Broker Assisted
    And I log out

    Then Primary Broker logs on to the Broker Agency Portal
    And Primary Broker clicks on the Employers tab
    Then Primary Broker should see Employer and click on legal name
    Then Primary should see the Employer Profile page as Broker
    When Primary Broker clicks on the Families tab
    Then Broker Assisted is a family
    Then Primary Broker goes to the Consumer page
    # Then Primary Broker is on the consumer home page
    # Then Primary Broker shops for plans
    # Then Primary Broker sees covered family members
    # Then Primary Broker should see the list of plans
    # Then Primary Broker selects a plan on the plan shopping page
    # And Primary Broker clicks on purchase button on the coverage summary page
    # And Primary Broker should see the receipt page
    Then Primary Broker logs out
