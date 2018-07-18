Feature: Employee Sign Up when Employer exists and has a matching roster employer
  In order for the Employee to purchase insurance
  Given my Employer exists and Employee is on the Employee Roster
  Given my Employer has an unpublished Plan Year
  The Employee should not be able to match Employer
  When my Employer publishes the Plan Year
  The Employee should be able to match Employer
  The Employee should be able to purchase Insurance

  Scenario: New employee without existing person
    Given Employee has not signed up as an HBX user
    And Soren White visits the employee portal
    When Soren White creates an HBX account
    And I select the all security question and give the answer
    When I have submit the security questions
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Soren White
    Then Employee should not see the matched employee record form
    Then Soren White logs out


  Scenario: New employee with existing person
    Given Employer for Soren White exists with a published health plan year
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
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And I should not see any plan which premium is 0
    When Employee selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee should see the receipt page
    Then Employee should see the "my account" page
    And Employee logs out
    # Then Employee should see the "Your Enrollment History" section
    # When Employee clicks a qle event
    # Then Employee can purchase a plan
