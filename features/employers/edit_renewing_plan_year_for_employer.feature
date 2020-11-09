Feature: As a renewing employer I should not be able to set contribution percentage less than 50 percent for employees

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft renewal employer with health benefits
    And there is an employer ABC Widgets
    And renewal employer ABC Widgets has draft and renewal active benefit applications
    And ABC Widgets employer has a staff role
    And staff role person logged in
    And update rating area

  Scenario Outline: As a renewing employer I should be able to set contribution percentage less than 50 percent for employees starting 2021
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    Then employer should see edit plan year button
    And employer clicked on edit plan year button
    Then employer should see form for benefit application and benefit package
    And employer updated <contribution_percent> contribution percent for the application
    Then employer should see your estimated montly cost
    And employer should see that the create plan year is <plan_year_btn_enabled>

    Examples:
      | contribution_percent | plan_year_btn_enabled |
      | 100                  | true                  |
      | 60                   | true                  |
      | 20                   | true                  |
