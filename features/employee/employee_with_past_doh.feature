Feature: Employee with past date of hire
    In order for the New Employee to purchase insurance
    Given Employer exists with active plan year
    Given New Employee is on the Census Employee Roster with past date as DOH and roster entry date as today
    Given New Employee does not have a pre-existing person
    Then New Employee should be able to match Employer
    And Employee should be able to purchase Insurance

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    Given Qualifying life events are present
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has enrollment_open benefit application
    And Acme Inc. employer has a staff role
    And there is a census employee record for Patrick Doe for employer Acme Inc.

  Scenario: New hire has enrollment period based on roster entry date
    Given staff role person logged in
    And Employee has past hired on date
    And Acme Inc. employer visit the Employee Roster
    Then Employer logs out
    Given Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    When Patrick Doe creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household Info: Family Members page and clicks Continue
    And Employee sees the Choose Coverage for your Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    And Employee sees the Enrollment Submitted page and clicks Continue
    Then Employee should see the "my account" page

    Given Acme Inc. eligibility rule has been set to first of month following or coinciding with date of hire
    Then Employee tries to complete purchase of another plan
    Then Employee should see the "my account" page

    Given Acme Inc. eligibility rule has been set to first of month following 30 days
    Then Employee tries to complete purchase of another plan
    Then Employee should see the "my account" page

    Given Acme Inc. eligibility rule has been set to first of month following 60 days
    Then Employee tries to complete purchase of another plan
    Then Employee should see the "my account" page
