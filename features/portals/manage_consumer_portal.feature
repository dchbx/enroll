@wip
Feature: Any Person with User account should be able to manage consumer portals

  Background: Setup site and benefit market catalog
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Xfinity Widgets

  Scenario Outline: User should be able to see add new consumer portal link
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab 
    Then person should see their <role> information under active portals
    And person clicks on add new portal link
    And person should be able to visit add new consumer portal
    Then person clicks on Add Role
    And person should see their indentifying information
    When user clicks on continue button
    Then user should see heading labeled personal information
    And person selects all mandatory radio option for us citizen
    And person goes to the next pages
    When I click on none of the situations listed above apply checkbox
    And I click on back to my account button
    Then I should land on home page
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab 
    Then person should see newly created consumer portal link
    And person logs out

    Examples:
      | role           |
      | Employee       |
      | Resident       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |
