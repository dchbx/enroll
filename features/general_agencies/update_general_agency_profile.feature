Feature: update general agency profile

  # Background: A general agency clicks on edit general agency and updates information
    # Given a CCA site exists with a benefit market
    # Given all permissions are present
    # Given a general agency, approved, confirmed, exists
    # And the ga login in
    # And the ga should see the home of ga

  # Scenario: A general agency updated information
    # When the ga clicks on EDIT GENERAL AGENCY button/link
    # Then the ga should see ga profile form to update informaton
    # When the ga enters personal information or general agency information or office location
    # And the ga clicks update general agency
    # Then the ga should see successful message.

  # Scenario: A general agency check for updated information
    # When the ga clicks on EDIT GENERAL AGENCY button/link
    # Then the ga should see ga profile form to update informaton
    # When the ga enters personal information or general agency information or office location
    # And the ga clicks update general agency
    # Then the ga should see successful message.
    # And the ga should see updated informaton on page
    # When the ga clicks on EDIT GENERAL AGENCY button/link
    # Then the ga should see updated informaton on page

  Scenario: Reactivating General Agency Staff Role
    Given a CCA site exists with a benefit market
    Given all permissions are present
    Given there is a General Agency exists for District Agency Inc
    And the staff Max Planck is primary ga staff for District Agency Inc
    And person record exists for John Doe
    And Max Planck logs on to the General Agency Portal
    And the primary staff clicks on the “Add General Agency Staff Role” button
    And a form appears that requires the primary staff to input First Name, Last Name, and DOB to submit
    When the primary staff enters the First Name, Last Name, and DOB of existing user John Doe
    Then the primary staff will be given a general agency staff role with the given General Agency Agency
    And the primary staff will now appear within the “General Agency Staff” table as Active and Linked
    # Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And user clicks the trash icon to remove a general agency role
    And user clicks Add General Agency Staff Role
    And user enters information for that terminated general agency staff and clicks save
    Then the terminated general agency staff role will be reactivated
