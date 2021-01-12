@wip
Feature: Any Person with User account should be able to manage employer poc portals

  Background: Setup site and benefit market catalog
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Xfinity Widgets

  Scenario Outline: User should be able to see add new employer poc portal link
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab
    Then person should see their <role> information under active portals
    And person clicks on add new portal link
    And person should see add new employer poc portal link
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Resident       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |

  Scenario Outline: User should be able to add employer poc portal
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab
    Then person should see their <role> information under active portals
    And person should be able to visit add new employer poc portal
    Then person should be able to see Employer Staff page
    And person searches for employer with name Xfinity Widgets
    Then person clicks on select this employer
    And person clicks on submit employer application
    Then person should see employer success message
    And person should see Xfinity Widgets's details under pending portals
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Resident       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |