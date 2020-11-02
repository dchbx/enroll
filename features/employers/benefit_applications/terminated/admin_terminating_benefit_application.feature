Feature: As an admin user I should have the ability to terminate a given Employer with a active benefit application.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has active benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Plan Years button
    Then the user will select benefit application to terminate
    When the user clicks Actions for that benefit application
    Then the user will see Terminate button

  Scenario Outline: As an HBX Staff with Super Admin subroles I should be able to terminate an benefit application
    When the user enters <termination_date> and other details for <termination_type> termination
    When user clicks submit button
    Then user should see termination successful message
    And user logs out

    Examples:
      | termination_type | termination_date |
      | voluntary        | any_day          |
      | non-payment      | mid_month        |
      | non-payment      | any_day          |
      | voluntary        | last_day         |
      | non-payment      | last_day         |
