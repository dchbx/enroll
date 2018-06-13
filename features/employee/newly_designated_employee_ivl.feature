Feature: Newly designated employees can purchase coverage only through renewing plan year
  In order to make employees purchase coverage only using renewal plan year
  Employee should be blocked from buying coverage under previous year plan year
  When IVL market is disabled.

  Scenario: Newly designated should see the shop market place workflow as default
    Given Congressional Employer for Soren White exists with active and renewing plan year
    And Soren White is newly designated
    And Employee has current hired on date
    And Employee has not signed up as an HBX user
    And Soren White visits the employee portal
    When Soren White creates an HBX account
    And I select the all security question and give the answer
    When I have submit the security questions
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Soren White
    Then Employee should see the matched employee record form
    And Employee should see the shop market place workflow as default

  Scenario: Newly designated should not see the individual market place workflow
    Given Congressional Employer for Soren White exists with active and renewing plan year
    And Soren White is newly designated
    And Employee has current hired on date
    And Employee has not signed up as an HBX user
    And Soren White visits the employee portal
    When Soren White creates an HBX account
    And I select the all security question and give the answer
    When I have submit the security questions
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Soren White
    Then Employee should see the matched employee record form
    And Employee should not see the individual market place workflow
