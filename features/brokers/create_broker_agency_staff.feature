Feature: Assign Broker Agency Staff to Broker Agency

  Scenario: Broker Staff has not signed up on the HBX
    Given there is a Broker Agency exists for District Brokers Inc
    Given all permissions are present
    And the broker Max Planck is primary broker for District Brokers Inc
    When Broker Staff visits the HBX Broker Registration form

    Given Broker Staff has not signed up as an HBX user
    Then Broker Staff should see the Broker Staff Registration form
    When Broker staff enters his personal information
    And Broker staff searches for Broker Agency which exists in EA
    And Broker staff should see a list of Broker Agencies searched and selects his agency
    Then Broker staff submits his application and see successful message

    Given Max Planck logs on to the Broker Agency Portal
    And there is a Staff with a “pending” broker staff role in the table
    When the Broker clicks on the approve button
    Then Broker should see the staff successfully approved message
    And Broker logs out

    Then Broker Staff should receive an invitation email from his Employer
    When Broker Staff visits invitation url in email
    Then Broker Staff should see the create account page
    When Broker Staff registers with valid information
    Then Broker Staff should see successful message with broker agency home page
    And Broker Staff logs out

    And Max Planck logs on to the Broker Agency Portal
    When the Broker removes Broker staff from Broker staff table
    Then Broker should see the staff successfully removed message
    And Broker logs out

  Scenario: Adding Existing person as Broker Staff to Broker Agency
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And person record exists for John Doe
    And Max Planck logs on to the Broker Agency Portal
    And the Broker clicks on the “Add Broker Staff Role” button
    And a form appears that requires the Broker to input First Name, Last Name, and DOB to submit
    When the Broker enters the First Name, Last Name, and DOB of existing user John Doe
    Then the Broker will be given a broker staff role with the given Broker Agency
    And the Broker will now appear within the “Broker Staff” table as Active and Linked

  Scenario: Adding Non Existing person as Broker Staff to Broker Agency
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And Max Planck logs on to the Broker Agency Portal
    And the Broker clicks on the “Add Broker Staff Role” button
    And a form appears that requires the Broker to input First Name, Last Name, and DOB to submit
    When the Broker enters the First Name, Last Name, and DOB of an non existing user in EA
    Then the Broker will not be given a broker staff role with the given Broker Agency
