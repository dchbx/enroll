Feature: As an admin user I should have the ability to <action> reinstate button on Employer datatable with reinstate feature <feature_switch> with resource registry

  Scenario Outline: Setup site, employer, and benefit application
    Given the Reinstate feature configuration is <feature_switch>
    And a CCA site exists with a benefit market
    And benefit market catalog exists for terminated initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has terminated benefit application
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Plan Years button
    Then the user will select benefit application to reinstate
    When the user clicks Actions for that benefit application
    Then the user will <action> Reinstate button
    And user logs out

  Examples:
    | feature_switch | action  |
    |    enabled     | see     |
    |    disabled    | not see |
