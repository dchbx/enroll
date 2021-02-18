Feature: Ability for Admin to create an Reinstated benefit application and verifies its census employee roster status

  Background: Setup site, employer, and benefit market catalogs
    Given a CCA site exists with a benefit market
    And benefit market catalog exists for active initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And the Reinstate feature configuration is enabled
  
  Scenario Outline: Initial Employer is in <aasm_state>. Admin is able to create reinstated benefit application and verifies its census employee roster status
    Given initial employer ABC Widgets has active benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And census employee Patrick Doe has a past DOH
    And employees for employer ABC Widgets have selected a coverage
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user clicks the Plan Years button
    Then the user will select benefit application to terminate
    When the user clicks Actions for current benefit application
    When the user clicks Actions for that benefit application
    Then the user will see Terminate button
    When the user enters <date> and other details for voluntary termination
    When user clicks submit button
    Then user should see termination successful message
    And update rating area
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user clicks the Plan Years button
    Then the user will select benefit application to reinstate
    And Admin reinstates benefit application
    Then Admin will see a Successful message
    And user logs out
    And staff role person logged in
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    Then employer should see <aasm_state> and reinstated benefit_application
    When staff role person clicks on employees link
    Then user able to see <bp_count> benefit package headers on the census employee roster
    And user able to see <es_count> enrollment status headers on the census employee roster
    And user logs out

    Examples:
      |    aasm_state       |   date     | bp_count | es_count |
      |    terminated       | last_month |   one    |   one    |
      | termination_pending | any_day    |   two    |   two    |

  Scenario Outline: Initial Employer is in <aasm_state>. Admin is able to create reinstated benefit application and verifies its census employee roster status
    Given initial employer ABC Widgets has active benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And census employee Patrick Doe has a past DOH
    And employees for employer ABC Widgets have selected a coverage
    And initial employer ABC Widgets application <to_state>
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Plan Years button
    Then the user will select benefit application to reinstate
    And Admin reinstates benefit application
    Then Admin will see a Successful message
    And user logs out
    And staff role person logged in
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    Then employer should see py_states states
    And staff role person clicks on employees link
    And user able to see one benefit package headers on the census employee roster
    And user able to see one enrollment status headers on the census employee roster
    And user logs out

    Examples:
      |    to_state          |  py_states                         |
      | retroactive_canceled |  [Canceled, Reinstated]            |
      |  canceled            |  [Canceled, Reinstated]            |
      |  terminated          |  [Coverage Terminated, Reinstated] |
