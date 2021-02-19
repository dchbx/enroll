@wip
Feature: Any Person with User account should be able to create General Agency poc portals

  Background: Setup site and benefit market catalog
    Given a CCA site exists with a benefit market
    And there is a General Agency exists for District Agency Inc
    And the staff Max Planck is primary ga staff for District Agency Inc

  Scenario Outline: User should be able to see add new general agency poc portal link
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab
    Then person should see their <role> information under active portals
    And person clicks on add new portal link
    And person should see add new general agency poc portal link
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Resident       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |

  Scenario Outline: User should be able to add general agency poc portal
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab
    Then person should see their <role> information under active portals
    And person should be able to visit add new general agency poc portal
    Then person should be able to see General Agency Staff page
    And person searches for ga with name District Agency Inc
    Then person clicks on select this ga
    And person clicks on submit ga application
    Then person should see ga success message
    And person should see District Agency Inc's details under pending portals
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Resident       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |