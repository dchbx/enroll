Feature: Employee goes through plan shopping with dependents when employer offers health and dental coverage

  Scenario: New employee with existing person
    Given Employer for Soren White exists with a published plan year offering health and dental
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
    Then Employee should see the dependents page
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Employee enters the dependent info of Sorens daughter
    When Employee clicks confirm member
    Then Employee should see 1 dependents
    When Employee clicks continue on the dependents page
    Then Employee should see all the family members names
    When Employee clicks health radio on the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the plan shopping page with no dependent
    When Employee clicks my insured portal link
    When Employee clicks shop for plans button
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the plan shopping page with one dependent
    And Employee logs out
