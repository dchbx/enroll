Feature: Assign General Agency Staff to General Agency

  Scenario: General Staff has not signed up on the HBX
    Given a CCA site exists with a benefit market
    Given there is a General Agency exists for District Agency Inc
    Given all permissions are present
    And the staff Max Planck is primary ga staff for District Agency Inc
    Given a general agency agent visits the DCHBX
    When they click the 'New General Agency' button

    Given GA Staff has not signed up as an HBX user
    Then GA Staff should see the General Agency Staff Registration form
    When GA staff enters his personal information
    And GA staff searches for General Agency which exists in EA
    And GA staff should see a list of General Agencies searched and selects his agency
    Then GA staff submits his application and see successful message

    And Max Planck logs on to the General Agency Portal
    And there is a Staff with a “pending” general agency staff role in the table
    When the primary staff clicks on the approve button
    Then the primary staff should see an approval popup
    Then the primary staff clicks on continue and approve button
    Then the primary staff should see the staff successfully approved message
    And new ga staff should receive an email
    And the primary staff logs out

    When new ga staff visits the link received in the approval email
    Then they should see an account creation form
    When new ga staff completes the account creation form and hit the 'Submit' button
    Then they should see a welcome message
    And they see the General Agency homepage
    And the primary staff logs out

    And Max Planck logs on to the General Agency Portal
    When the primary staff removes ga staff from ga staff table
    Then the primary staff should see the staff successfully removed message
    And the primary staff logs out

  Scenario: Adding Existing person as General Agency Staff to General Agency
    Given there is a General Agency exists for District Agency Inc
    And the staff Max Planck is primary ga staff for District Agency Inc
    And person record exists for John Doe
    And Max Planck logs on to the General Agency Portal
    And the primary staff clicks on the “Add General Agency Staff Role” button
    And a form appears that requires the primary staff to input First Name, Last Name, and DOB to submit
    When the primary staff enters the First Name, Last Name, and DOB of existing user John Doe
    Then the primary staff will be given a general agency staff role with the given General Agency Agency
    And the primary staff will now appear within the “General Agency Staff” table as Active and Linked

  Scenario: Adding Non Existing person as General Agency Staff to General Agency
    Given there is a General Agency exists for District Agency Inc
    And the staff Max Planck is primary ga staff for District Agency Inc
    And Max Planck logs on to the General Agency Portal
    And the primary staff clicks on the “Add General Agency Staff Role” button
    And a form appears that requires the primary staff to input First Name, Last Name, and DOB to submit
    When the primary staff enters the First Name, Last Name, and DOB of an non existing user in EA
    Then the primary staff will not be given a general agency staff role with the given General Agency Agency
