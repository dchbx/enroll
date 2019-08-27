Feature: update general agency profile

  Background: General agency logs in
    Given there is a General Agency exists for District Agency Inc
    And the staff Primary Ga is primary ga staff for District Agency Inc
    And Primary Ga logs on to the General Agency Portal
    And the ga should see the home of ga

  Scenario: General agency clicks on edit general agency and updates information
    When the ga clicks on EDIT GENERAL AGENCY button/link
    # Then the ga should see ga profile form to update informaton
    When the ga enters personal information or general agency information or office location
    And the ga clicks update general agency
    Then the ga should see successful message.
    And the ga should see updated informaton on page
    When the ga clicks on EDIT GENERAL AGENCY button/link
    Then the ga should see updated informaton on page
