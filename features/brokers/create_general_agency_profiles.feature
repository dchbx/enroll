@general_agency_enabled
Feature: Create General Agency and General Agency Staff Role
  Scenario: General Agency has not signed up on the HBX
    When General Agency visit the HBX General Agency Registration form
      Then General Agency should see the New General Agency form
      When General Agency enters personal information for agency
      And General Agency enters general agency information
      And General Agency enters office location for default_office_location
      And General Agency clicks on Create General Agency
      Then General Agency should see general agency registration successful message

    Given Hbx Admin exists
      When Hbx Admin logs on to the Hbx Portal
      And Hbx Admin clicks on the link of General agency
      Then Hbx Admin should see the list of general agencies
      When Hbx Admin clicks the link of Housecare Inc
      Then Hbx Admin should see the show page of general agency
      When Hbx Admin clicks on the Staff tab
      Then Hbx Admin should see the list of general agency staff
      When Hbx Admin clicks the link of staff role
      Then Hbx Admin should see the detail of staff
      When Hbx Admin clicks on approve staff button
      Then Hbx Admin should see the staff successful approved message
      And Hbx Admin logs out

    Then General Agency Staff should receive an invitation email for staff
      When General Agency Staff visits invitation url in email for staff
      Then General Agency Staff should see the create account page
      When General Agency Staff registers with valid information for staff
      Then General Agency Staff should see successful message with general agency home page
      And General Agency Staff logs out

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
