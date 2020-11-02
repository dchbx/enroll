Feature: Employee with past date of hire
    In order for the New Employee to purchase insurance
    Given Employer exists with active plan year
    Given New Employee is on the Census Employee Roster with past date as DOH and roster entry date as today
    Given New Employee does not have a pre-existing person
    Then New Employee should be able to match Employer
    And Employee should be able to purchase Insurance

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a fehb benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an fehb employer Acme Inc.
    And initial employer Acme Inc. has enrollment_open benefit application
    And Acme Inc. employer has a staff role
    And there is a census employee record for Patrick Doe for employer Acme Inc.

  Scenario: New hire has enrollment period based on roster entry date
    Given Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    When Employee clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page

    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the enrollment_open plan year
    When Patrick Doe selects a plan on the plan shopping page
    Then Patrick Doe should see coverage summary page with enrollment_open plan year start as coverage effective date
    Then Patrick Doe should see receipt page with enrollment_open plan year start as coverage effective date
    Then Patrick Doe should see "my account" page with enrollment