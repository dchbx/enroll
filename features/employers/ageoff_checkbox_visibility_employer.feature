Feature: Ageoff Checkbox visibility for Employer Flow

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    Given Qualifying life events are present
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And there are 2 employees for ABC Widgets
    When staff role person logged in
    Then ABC Widgets employer visit the Employee Roster

  Scenario: Employer views their employees and ER Selects existing Employee
    Given there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And there is a census employee record for Patrick Doe for employer ABC Widgets
    When staff role person logged in
    Then ABC Widgets employer visit the Employee Roster
    When employer selects Patrick Doe employee on Employee Roster
    Then employer should not see the Ageoff Exclusion checkbox

