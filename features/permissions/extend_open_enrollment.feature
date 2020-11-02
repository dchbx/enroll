Feature: As a Super Admin I will be the only user
  that is able to see & access the "Extension of Open Enrollment" Feature.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has enrollment_open benefit application

  Scenario Outline: HBX Staff with <subrole> subroles should <action> Extend Open Enrollment button
    Given that a user with a HBX staff role with <subrole> subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will <action> the Extend Open Enrollment button

    Examples:
      | subrole       | action  |
      | Super Admin   | see     |
      | HBX Staff     | not see |
      | HBX Read Only | not see |
      | Developer     | not see |
      | HBX Tier3     | see     |
