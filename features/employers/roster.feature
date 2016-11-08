Feature: Employer can view their employees

  Scenario: Employer views their employees
    Given an employer exists
    And the employer has employees
    And the employer is logged in
    When they visit the Employee Roster
    And click on one of their employees
    Then they should see that employee's details
    And employer logs out
  Scenario: Employer views their employees and terminates one employee
    Given an employer exists
    And the employer has employees
    And the employer is logged in
    When they visit the Employee Roster
    Then employer should not see termination date column
    And clicks on terminate employee
    Then employer clicks on terminated filter
    Then employer sees termination date column
    And employer clicks on terminated employee
    Then they should see that employee's details
    And employer clicks on back button
    Then employer should see employee roaster
    And employer should also see termination date
    And employer clicks on all employees
    Then employer sees termination date column
    And employer clicks on terminated employee
    Then they should see that employee's details
    And employer clicks on cancel button
    Then employer should see employee roaster
    And employer should also see termination date
    And employer logs out