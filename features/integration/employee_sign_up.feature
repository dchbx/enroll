Feature: Employee Sign Up when Employer exists and has a matching roster employer
    In order for the Employee to purchase insurance
    Given my Employer exists and Employee is on the Employee Roster
    Given my Employer has an unpublished Plan Year
    The Employee should not be able to match Employer
    When my Employer publishes the Plan Year
  The Employee should be able to match Employer
  The Employee should be able to purchase Insurance

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Acme Inc.
    And Acme Inc. employer has a staff role

  Scenario: New employee without existing person
    Given Employee has not signed up as an HBX user
    And Soren White visits the employee portal
    When Soren White creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Soren White
    Then Employee should not see the matched employee record form
    Then Soren White logs out

#  Scenario: New employee with existing person
#    Given staff role person logged in
#    And initial employer Acme Inc. has enrollment_open benefit application
#    And Acme Inc. employer visit the Employee Roster
#    And there is a census employee record for Patrick Doe for employer Acme Inc.
#    Then Employer logs out
#    And Employee has not signed up as an HBX user
#    And Patrick Doe visits the employee portal
#    When Patrick Doe creates an HBX account
#    When Employee goes to register as an employee
#    Then Employee should see the employee search page
#    When Employee enters the identifying info of Patrick Doe
#    Then Employee should see the matched employee record form
#    When Employee accepts the matched employer
#    When Employee completes the matched employee form for Patrick Doe
#    Then Employee should see the dependents page
#    When Employee clicks continue on the dependents page
#    Then Employee should see the group selection page
#    When Employee clicks continue button on group selection page for dependents
#    Then Employee should see the list of plans
#    When Employee selects a plan on the plan shopping page
#    When Employee clicks on Confirm button on the coverage summary page
#    Then Employee should see the receipt page
#    Then Employee should see the "my account" page
#    And Employee logs out
