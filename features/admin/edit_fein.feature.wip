@wip
Feature: Update FEIN
  In order to update FEIN
  User should have the role of an Super Admin

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And there is an employer Xfinity Enterprise

  Scenario Outline: HBX Staff with Super Admin enters FEIN with/without 9 digits
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Change FEIN link in the Actions dropdown for ABC Widgets Employer
    And the user enters <enters>
    And the user clicks submit button
    Then an <messagetype> will be presented as <message>

      Examples:
        | enters                                                | messagetype         | message                               |
        | FEIN with less than nine digits                       | warning message     | FEIN must be at least nine digits     |
        | unique FEIN with nine digits                          | success message     | FEIN Update Successful                |
  
  Scenario: HBX Staff with Super Admin enters FEIN for existing employer
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Change FEIN link in the Actions dropdown for ABC Widgets Employer
    And the user enters FEIN matches an existing Employer Profile FEIN  
    And the user clicks submit button
    Then an warning message will be presented as FEIN matches HBX ID Legal Name
