Feature: HBX staff subroles able to see the Ageoff Exclusion checkbox

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has enrollment_open benefit application
    And ABC Widgets has census employee, person record, and active coverage for employee Patrick Doe

  Scenario Outline: HBX Staff with <subrole> subroles should <action> the Ageoff Exclusion checkbox
    Given that a user with a HBX staff role with <subrole> subrole exists and is logged in
    When the user is on the Family Index of the Admin Dashboard
    And the user clicks on Families tab
    And the user clicks on the name of person Patrick Doe from family index_page
    And the user clicks on the Manage Family button
    And the user clicks on the Personal portal
    Then the user will <action> the Ageoff Exclusion checkbox
    When the user clicks on the Family portal
    And the user clicks on Add Member
    Then the user will <action> the Ageoff Exclusion checkbox

    Examples:
      | subrole            | action  |
      | Super Admin        | see     |
      | HBX Tier3          | see     |
      | HBX Staff          | see     |
      | Hbx CSR Supervisor | see     |
      | Hbx CSR Tier1      | see     |
      | Hbx CSR Tier2      | see     |