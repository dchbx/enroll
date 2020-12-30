Feature: COBRA basic

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    And there is an employer EnterPrise Limited
    And EnterPrise Limited employer has a staff role
    And there are 2 employees for EnterPrise Limited

Scenario: Employer terminates and Initiate COBRA to Unlinked employee
    Given staff role person logged in
    And EnterPrise Limited employer terminates employees
    And EnterPrise Limited employer visit the Employee Roster
    Then employer clicks on terminated filter
    And employer clicks on Actions drop down for one of active employee
    And employer should see the Initiate cobra button
    When employer clicks on Initiate cobra button
    Then employer should see Enter effective date for Initiate cobra Action
    And employer should see default cobra start date
    And employer sets cobra start date to two months after termination date
    When EnterPrise Limited employer clicks on Initiate COBRA button
    Then employer should see the Initiate cobra success flash notice
    And employer clicks on all employees
    And employer should see census employee status as Cobra eligible

Scenario: Employer terminates and Initiate COBRA to enrolled employee
    Given staff role person logged in
    And initial employer EnterPrise Limited has active benefit application
    And employees for EnterPrise Limited have a selected coverage
    And EnterPrise Limited employer visit the Employee Roster
    And EnterPrise Limited employer terminates employees
    Then employer clicks on terminated filter
    And employer clicks on Actions drop down for one of active employee
    And employer should see the Initiate cobra button
    When employer clicks on Initiate cobra button
    Then employer should see Enter effective date for Initiate cobra Action
    And employer should see default cobra start date
    And employer sets cobra start date to two months after termination date
    When EnterPrise Limited employer clicks on Initiate COBRA button
    Then employer should see the Initiate cobra success flash notice
    And employer clicks on all employees
    And employer should see census employee status as Cobra Enrolled

  Scenario: Employer tries to initiate COBRA with COBRA begin date before termination date
    Given staff role person logged in
    And initial employer EnterPrise Limited has active benefit application
    And employees for EnterPrise Limited have a selected coverage
    And EnterPrise Limited employer visit the Employee Roster
    And EnterPrise Limited employer terminates employees
    Then employer clicks on terminated filter
    And employer clicks on Actions drop down for one of active employee
    And employer should see the Initiate cobra button
    When employer clicks on Initiate cobra button
    Then employer should see Enter effective date for Initiate cobra Action
    And employer should see default cobra start date
    And employer sets cobra start date to two months before termination date
    When EnterPrise Limited employer clicks on Initiate COBRA button
    Then employer should see the Initiate cobra error flash notice
