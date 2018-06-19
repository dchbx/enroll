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
    # Re-enable this when we figure out how to get column show/hide to work dynamically
    # Then employer should not see termination date column
    And clicks on terminate employee
    Then employer clicks on terminated filter
    Then employer sees termination date column
    And employer clicks on terminated employee
    Then they should see that employee's details
    And employer clicks on back button
    Then employer should see employee roaster
    And employer clicks on all employees
    Then employer sees termination date column
    And employer clicks on terminated employee
    Then they should see that employee's details
    And employer clicks on cancel button
    Then employer should see employee roaster
    And employer logs out
  Scenario: Employer views their employees and this ER has linked EEs
    Given an employer exists
    And the employer has employees
    And the employer is logged in
    When they visit the Employee Roster
    And employer clicks on linked employee with address
    Then employer should not see the address on the roster
    And employer clicks on cancel button
    And employer clicks on linked employee without address
    Then employer should see the address on the roster
    And employer populates the address field
    And employer clicks on update employee
    Then employer should not see the address on the roster
    And employer clicks on cancel button
    And employer clicks on non-linked employee with address
    Then employer should not see the address on the roster
    And employer clicks on cancel button
    And employer clicks on non-linked employee without address
    Then employer should see the address on the roster
    And employer logs out
  Scenario: Employer adds employee with future hire date
    Given an employer exists
    And the employer has employees
    And the employer is logged in
    When they visit the Employee Roster
    And clicks on the Add New Employee button
    Then fill the form with hired date as future date
    Then employer should see the message Your employee was successfully added to your roster on page
    And employer logs out

#   We don't support user searches for employee roster yet
#  Scenario: When ER searches for an EE on the roster through different tabs
#    Given an employer exists
#    And the employer has employees
#    And the employer is logged in
#    When they visit the Employee Roster
#    Then ER should land on active EE tab
#    And ER enters active EE name on search bar
#    Then ER should see the active searched EE on the roster page
#    Then employer clicks on terminated filter
#    Then ER should land on terminated EE tab
#    And ER should see no results
#    Then ER clears the search value in the search box
#    And ER clicks on search button
#    Then ER should see all the terminated employees
#    And ER enters terminated EE name on search bar
#    Then ER should see the terminated searched EE on the roster page
#    And employer logs out
