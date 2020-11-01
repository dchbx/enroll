Feature: Add Plan Year For Employer

  Background: Setup site, employer
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And staff role person logged in
    And update rating area

  Scenario Outline: Adding a new plan year
    And <minimum_contribution_factor> is updated on benefit market catalog
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    Then employer should see add plan year button
    And employer clicked on add plan year button
    Then employer should see continue button disabled
    And employer filled all the fields on benefit application form
    And employer clicked on continue button
    Then employer should see form for benefit package
    And employer filled all the fields on benefit package form for initial application
    And employer selected by metal level plan offerings
    Then employer should see gold metal level type
    And employer clicked on gold metal level
    Then employer should see create plan year button disabled
    And employer selected <contribution_percent> contribution percent for the application
    Then employer should see your estimated montly cost
    And employer clicked on create plan year button
    Then employer should see a draft benefit application

    Examples:
      | contribution_percent | minimum_contribution_factor |
      | 100                  | 0.5                         |


  Scenario Outline: Creating a new plan year should honor contribution factor from benefit market catalogs
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    Then employer should see add plan year button
    And employer clicked on add plan year button
    Then employer should see continue button disabled
    And employer filled all the fields on benefit application form
    And employer clicked on continue button
    Then employer should see form for benefit package
    And employer filled all the fields on benefit package form for initial application
    And employer selected by metal level plan offerings
    Then employer should see gold metal level type
    And employer clicked on gold metal level
    Then employer should see create plan year button disabled
    And employer selected <contribution_percent> contribution percent for the application
    Then employer should see your estimated montly cost
    And employer should see that the create plan year is <plan_year_btn_enabled>

    Examples:
      | contribution_percent | plan_year_btn_enabled |
      | 100                  | true                  |
      | 60                   | true                  |
      | 20                   | true                  |