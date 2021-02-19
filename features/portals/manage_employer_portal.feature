@wip
Feature: Any Person with User account should be able to manage employer portals

  Background: Setup site and benefit market catalog
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits

  Scenario Outline: User should be able to see add new portal link based on eligibility
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab
    Then person should see their <role> information under active portals
    And person <add_new_portal_visible> see add new portal link

    Examples:
      | role           | add_new_portal_visible |
      | Employee       |       should           |
      | Consumer       |       should           |
      | Resident       |       should not       |
      | Employer Staff |       should           |
      | GA Staff       |       should           |
      | Broker Staff   |       should           |

  Scenario Outline: User should be able to add employer portal based on eligibility
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on my portals tab
    Then person should see their <role> information under active portals
    And person should be able to visit add new portal
    Then person should be able to see Available Portals page
    And person should be able to click add employer portal
    Then person filled all the fields in the employer information form
    And person clicks on add portal
    Then person should see a modal confirmation popup
    And person clicks on add role on pop up
    Then person should see employer home page

    Examples:
      | role           |
      | Employee       |
      | Consumer       |
      | Employer Staff |
      | GA Staff       |
      | Broker Staff   |