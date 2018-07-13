@general_agency_enabled
Feature: Create a General Agency Profile

  Scenario: A General Agency Submits Application
    Given a general agency agent visits the DCHBX
    When they click the 'New General Agency' button
    Then they should see the new general agency form
    When they complete the new general agency form and hit the 'Submit' button
    Then they should see a confirmation message
    And a pending approval status

  Scenario: A General Agency is Approved
    Given an HBX admin exists
    And a general agency, pending approval, exists
    When the HBX admin visits the general agency list
    Then they should see the pending general agency
    When they click the link of general agency
    Then they should see the home of general agency
    When they visit the list of staff
    Then they should see the name of staff
    When they approve the general agency
    Then they should see updated status
    And the general agency should receive an email

  Scenario: A General Agency Creates an Account
    Given a general agency, approved, awaiting account creation, exists
    When the HBX admin visits the link received in the approval email
    Then they should see an account creation form
    When they complete the account creation form and hit the 'Submit' button
    Then they should see a welcome message
    And they see the General Agency homepage
