Feature: Employee goes through plan shopping with dependents when employer offers health and dental coverage


  Scenario: New employee with existing person
    Given Employer for Soren White exists with a published plan year offering health and dental
    And Employee has not signed up as an HBX user
    And Soren White visits the employee portal
    When Soren White creates an HBX account
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
    When Employee clicks continue on the dependents page
    Then Employee should see the group selection page with health or dental dependents list
    When Employee clicks health radio on the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the plan shopping page with no dependent
    When Employee clicks my insured portal link
    When Employee clicks shop for plans button
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the plan shopping page with one dependent
    And Employee logs out
  
  Scenario: New employee with existing person with co-employee (same employer) dependent
    Given Employer for Soren White also has their spouse as an employee and a published plan year
    And Employee has not signed up as an HBX user
    And Soren White visits the employee portal
    When Soren White creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Soren White
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Soren White
    Then Employee should see the dependents page
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Soren White enters the dependent info of their spouse
    When Employee clicks confirm member
    When Employee clicks continue on the dependents page
    Then Employee should see the group selection page with health or dental dependents list
    When Employee clicks health radio on the group selection page
    When Employee clicks continue on the group selection page
    Then Soren White should see the plan shopping page with one dependent
    When Employee clicks my insured portal link
    When Employee clicks shop for plans button
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Soren White should see the plan shopping page with one dependent
    Then Soren White should click the dependent link
    When Soren White clicks continue on the dependent link from the plan shopping page
    Then Soren White clicks the close button the dependents modal
    When Employee selects a plan on the plan shopping page
    When Employee should be able to confirm plan selection
    And Employee logs out
    And Patrick Doe visits the employee portal
    When Patrick Doe creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
    Then Employee should see the dependents page
    When Employee clicks Add Member
    Then Employee should see the new dependent form
    When Patrick Doe enters the dependent info of their spouse
    When Employee clicks confirm member
    When Employee clicks continue on the dependents page
    Then Employee should see the group selection page with health or dental dependents list
    When Employee clicks health radio on the group selection page
    When Employee clicks continue on the group selection page
    Then Patrick Doe should see the plan shopping page with one dependent
    When Employee clicks my insured portal link
    When Employee clicks shop for plans button
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Patrick Doe should see the plan shopping page with one dependent
    Then Patrick Doe should click the dependent link
    When Patrick Doe clicks continue on the dependent link from the plan shopping page
    Then Patrick Doe clicks the close button the dependents modal
    When Employee selects a plan on the plan shopping page
    When Employee should be able to confirm plan selection
    And Employee logs out
