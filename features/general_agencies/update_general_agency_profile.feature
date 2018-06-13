@general_agency_enabled
Feature: update general agency profile

  Background: A general agency clicks on edit general agency and updates information
    Given a general agency, approved, confirmed, exists
    And the ga login in
    And the ga should see the home of ga

  Scenario: A general agency updated information
    When the ga clicks on EDIT GENERAL AGENCY button/link
    Then the ga should see ga profile form to update informaton
    When the ga enters personal information or general agency information or office location
    And the ga clicks update general agency
    Then the ga should see successful message.

  Scenario: A general agency check for updated information
    When the ga clicks on EDIT GENERAL AGENCY button/link
    Then the ga should see ga profile form to update informaton
    When the ga enters personal information or general agency information or office location
    And the ga clicks update general agency
    Then the ga should see successful message.
    And the ga should see updated informaton on page
    When the ga clicks on EDIT GENERAL AGENCY button/link
    Then the ga should see updated informaton on page


