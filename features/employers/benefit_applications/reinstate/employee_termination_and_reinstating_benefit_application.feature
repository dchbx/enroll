Feature: Admin reinstating benefit application and terminating census employee with past and future date

  Background: Setup site, employer, and benefit market catalogs
    Given a CCA site exists with a benefit market
    And benefit market catalog exists for active initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And the Reinstate feature configuration is enabled
    And Qualifying life events are present

  Scenario Outline: Employer terminating census employee and Admin reinstating benefit application
    Given initial employer ABC Widgets has active benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And census employee Patrick Doe has a past DOH
    And employees for employer ABC Widgets have selected a coverage
    And initial employer ABC Widgets application terminated
    And staff role person logged in
    When ABC Widgets is logged in and on the home page
    And staff role person clicks on employees link
    When staff role clicks on Actions drop down for Patrick Doe
    And staff role person terminate employee Patrick Doe with <termination_date>
    Then staff role should see the terminated success flash notice
    And staff role clicks log out
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
    And staff role person clicks on employees link
    When staff role clicks on button <enrollment_status> for datatable
    And staff role person clicks on employee Patrick Doe
    Then employer should see terminated census employee's details
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    Then employee should see <enrollment_status> enrollment
    And user logs out

    Examples:
      |  termination_date  | enrollment_status |
      |    pastdate        | terminated        |
      |    futuredate      | termination_pending |