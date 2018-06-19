Feature: Employee with future date of hire
  In order for the New Employee to purchase insurance
  Given Employer exists with active plan year
  Given New Employee is on the Census Employee Roster with future date as DOH and roster entry date as today
  Given New Employee does not have a pre-existing person
  Then New Employee should be able to match Employer
  And Employee should be able to purchase Insurance


  Scenario: New hire has future enrollment period
    Given Employer for Soren White exists with a published health plan year
    And Employee has future hired on date
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
    Then Employee should see "not yet eligible" error message

    Given I set the eligibility rule to first of month following or coinciding with date of hire
    When Employee clicks "Shop for Plans" on my account page
    When Employee clicks continue on the group selection page
    Then Employee should see "not yet eligible" error message

    Given I set the eligibility rule to first of month following 30 days
    When Employee clicks "Shop for Plans" on my account page
    When Employee clicks continue on the group selection page
    Then Employee should see "not yet eligible" error message

    Given I set the eligibility rule to first of month following 60 days
    When Employee clicks "Shop for Plans" on my account page
    When Employee clicks continue on the group selection page
    Then Employee should see "not yet eligible" error message

    When Employee enters Qualifying Life Event
    When Employee clicks continue on the family members page
    When Employee clicks continue on the group selection page
    Then Employee should see "not yet eligible" error message

    Given I reset employee to future enrollment window
    Then Employee tries to complete purchase of another plan
    Then Employee should see "my account" page with enrollment
