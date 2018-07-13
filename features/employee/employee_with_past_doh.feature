Feature: Employee with past date of hire
  In order for the New Employee to purchase insurance
  Given Employer exists with active plan year
  Given New Employee is on the Census Employee Roster with past date as DOH and roster entry date as today
  Given New Employee does not have a pre-existing person
  Then New Employee should be able to match Employer
  And Employee should be able to purchase Insurance


  Scenario: New hire has enrollment period based on roster entry date
    Given Employer for Soren White exists with a published health plan year
    And Employee has past hired on date
    And Employee has not signed up as an HBX user
    And Soren White visits the employee portal
    When Soren White creates an HBX account
    And I select the all security question and give the answer
    When I have submit the security questions
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Soren White
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Soren White
    When Employee clicks continue on the dependents page
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And I should not see any plan which premium is 0
    When Employee selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee should see the receipt page
    Then Employee should see "my account" page with enrollment

    Given I set the eligibility rule to first of month following or coinciding with date of hire
    Then Employee tries to complete purchase of another plan
    Then Employee should see "my account" page with enrollment

    Given I set the eligibility rule to first of month following 30 days
    Then Employee tries to complete purchase of another plan
    Then Employee should see "my account" page with enrollment

    Given I set the eligibility rule to first of month following 60 days
    Then Employee tries to complete purchase of another plan
    Then Employee should see "my account" page with enrollment
