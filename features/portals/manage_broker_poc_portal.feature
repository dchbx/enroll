@wip
Feature: Any Person with User account should be able to create Broker poc portals

  Background: Setup site and benefit market catalog
    Given a CCA site exists with a benefit market
    And there is a Broker Agency exists for District Brokers Inc

  Scenario Outline: User should be able to see add new broker poc portal link
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab
    Then person should see their <role> information under active portals
    And person clicks on add new portal link
    And person should see add new broker poc portal link
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Resident       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |

  Scenario Outline: User should be able to add broker poc portal
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab
    Then person should see their <role> information under active portals
    And person should be able to visit add new broker poc portal
    Then person should be able to see Broker Staff page
    And person searches for broker with name District Brokers Inc
    Then person clicks on select this broker
    And person clicks on submit broker application
    Then person should see broker success message
    And person should see District Brokers Inc's details under pending portals
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Resident       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |