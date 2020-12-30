Feature: As a Super Admin I will be the only user
  that is able to see & access the "Force Publish" Feature.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets

  Scenario Outline: HBX Staff with <subrole> subroles should <action> Send Secure message
    Given that a user with a HBX staff role with <subrole> subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    Then the user will <action> the Send Secure Message button

    Examples:
      | subrole       | action  |
      | Super Admin   | see     |
      | HBX Tier3     | see     |
      | HBX Staff     | not see |
      | HBX Read Only | not see |
      | Developer     | not see |