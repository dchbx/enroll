Feature: Employer can view their employees

  Scenario: Employer views their employees
    Given an employer exists
    And the employer has employees
    And the employer is logged in
    When they visit the Employee Roster
    And click on one of their employees
    Then they should see that employee details
    And employer logs out
