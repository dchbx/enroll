Feature: Edit Plan Year For Renewing Employer

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits

    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And renewal employer ABC Widgets has active and renewal draft benefit applications
    When staff role person logged in

  Scenario: Employer should be able to change open enrollment end dates
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    Then employer should see edit plan year button
    And employer clicked on edit plan year button
    And employer clicked on edit plan year button
    Then employer updates open enrollment end date to 11
    And employer clicks on update plan year
    And employer clicked on edit plan year button
    Then employer updates open enrollment end date to 13
    And employer clicks on update plan year
    And employer should see a success message
    And employer logs out