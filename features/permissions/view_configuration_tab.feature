Feature: As a Super Admin I will be the only user
  that is able to see & access the Config tab

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    Given benefit market catalog exists for ABC Widgets initial employer with health benefits
    And initial employer ABC Widgets has enrollment_open benefit application


  Scenario Outline: HBX Staff with <subrole> subroles should <action> the config tab
    Given that a user with a HBX staff role with <subrole> subrole exists and is logged in
    And the user is on the Main Page
    Then the user will <action> the Config tab

    Examples:
      | subrole       | action |
      | Super Admin   | see    |
      | HBX Tier3     | see    |
      | HBX Staff     | see    |
      | HBX Read Only | see    |
      | Developer     | see    |

  Scenario: HBX Staff with Super Admin subroles should not have the option to time travel
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Main Page
    And the user goes to the Config Page
    Then the user will not see the Time Tavel option

  Scenario: HBX Staff with Super Admin subroles and a time travel ability enabled should have the option to time travel
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user with a HBX staff role with Super Admin subrole updates permisssions to time travel
    And the user is on the Main Page
    And the user goes to the Config Page
    Then the user will see the Time Tavel option



