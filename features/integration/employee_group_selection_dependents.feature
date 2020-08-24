Feature: Employee goes through plan shopping with dependents when employer offers health and dental coverage

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Acme Inc.
    And Acme Inc. employer has a staff role

  Scenario: New employee with existing person
    Given staff role person logged in
    And initial employer Acme Inc. has enrollment_open benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And Acme Inc. employer visit the Employee Roster
    Then Employer logs out
    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    When Patrick Doe creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    Then Employee should see the dependents page
    When Employee clicks Add New Person
    Then Employee should see the new dependent form
    When Employee enters the dependent info of Patrick wife
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    When Employee clicks continue on the dependents page
    Then Employee should see the relationship selection
    When Employee selects relationship and clicks Add Relationship
    And Employee clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue button on group selection page for dependents
    Then Employee should see the list of plans
    # And I should not see any plan which premium is 0 TODO Figure out why we can't have 0
    When Employee selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee should see the receipt page
    Then Employee should see the "my account" page
    And Employee logs out
