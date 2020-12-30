Feature: Employer Profile
  In order for employers to manage their accounts
  Employer Staff should be able to add and delete employer staff roles

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And Hannah is a person
    And Hannah is census employee to ABC Widgets
    And staff role person logged in
    And ABC Widgets is logged in and on the home page

  Scenario: Employer adds another staff role person with invalid details
    When employer ABC Widgets decides to Update Business information
    And employer clicks on the Add employer staff role link
    And ABC Widgets fills in all mandatory fields and clicks on save
    Then employer should see a error flash message
    Then staff role logs out

  Scenario: Employer adds another staff role person with valid details
    And employer ABC Widgets decides to Update Business information
    And employer clicks on the Add employer staff role link
    And Employer enters Hannah details and clicks on save
    Then employer should see a success flash message
    Then staff role logs out

  Scenario: An employer staff adds two roles and deletes one
    Given Sarah is a person
    Given Sarah has already provided security question responses
    Given BusyGuy is a person
    Given BusyGuy has already provided security question responses
    And employer ABC Widgets decides to Update Business information
    Then Point of Contact count is 1
    Then John cannot remove EmployerStaffRole from John
    Then Point of Contact count is 1
    When John adds an EmployerStaffRole to Sarah
    Then Point of Contact count is 2
    When John removes EmployerStaffRole from Sarah
    Then Point of Contact count is 1
    When John adds an EmployerStaffRole to Sarah
    Then Point of Contact count is 2
    # When John removes EmployerStaffRole from John  #Ticket-85321
    Then John logs out