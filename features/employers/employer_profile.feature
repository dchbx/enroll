Feature: Employer Profile
  In order for employers to manage their accounts
  Employer Staff should be able to add and delete employer staff roles
  
  Scenario: An existing person asks for a staff role at an existing company
    Given Hannah is a person
    Given Hannah is the staff person for an employer
    Given BusyGuy is a person
    Given BusyGuy accesses the Employer Portal

    Given BusyGuy enters data for Turner Agency, Inc
    Then BusyGuy is notified about Employer Staff Role application is pending
    Then BusyGuy logs out
    When Hannah accesses the Employer Portal
    And Hannah decides to Update Business information
    Then Point of Contact count is 2
    Then Hannah approves EmployerStaffRole for BusyGuy

  Scenario: An employer staff adds two roles and deletes one
    Given Sarah is a person
    Given Hannah is a person
    Given Hannah is the staff person for an employer
    When Hannah accesses the Employer Portal
    And Hannah decides to Update Business information
    Then Point of Contact count is 1

    Then Hannah cannot remove EmployerStaffRole from Hannah
    Then Point of Contact count is 1
    When Hannah adds an EmployerStaffRole to Sarah
    Then Point of Contact count is 2
    When Hannah removes EmployerStaffRole from Sarah
    Then Point of Contact count is 1

    When Hannah adds an EmployerStaffRole to Sarah
    Then Point of Contact count is 2

    When Hannah removes EmployerStaffRole from Hannah
    Then Hannah sees new employer page
    Then Hannah logs out

    When Sarah accesses the Employer Portal
    And Sarah decides to Update Business information
    Then Point of Contact count is 1
    Then Sarah logs out
  
  Scenario: A new person asks for a staff role at an existing company
    Given Hannah is a person
    Given Hannah is the staff person for an employer
    Given NewGuy is a user with no person who goes to the Employer Portal
    Given NewGuy enters first, last, dob and contact info
    Given NewGuy enters data for Turner Agency, Inc
    Then NewGuy is notified about Employer Staff Role application is pending
    Then NewGuy logs out
    # Could be HBXAdmin or Broker
    Given Admin is a person
    Given Admin has HBXAdmin privileges
    And Admin accesses the Employers tab of HBX portal
    Given Admin selects Hannahs company
    Given Admin decides to Update Business information
    Then Point of Contact count is 2
    Then Admin approves EmployerStaffRole for NewGuy

Scenario: A new person creates a new company
    Given NewGuy is a user with no person who goes to the Employer Portal
    Given NewGuy enters first, last, dob and contact info
    Given a FEIN for a new company
    Given NewGuy enters Employer Information
    Then NewGuy becomes an Employer
    When NewGuy decides to Update Business information
    Then Point of Contact count is 1

Scenario: A new person claims an existing unclaimed company
   Given NewGuy is a user with no person who goes to the Employer Portal
    Given NewGuy enters first, last, dob and contact info
    Given a FEIN for an existing company
    Given NewGuy enters Employer Information
    Then NewGuy becomes an Employer
    When NewGuy decides to Update Business information
    Then Point of Contact count is 1
    And NewGuy logs out

Scenario: A new person claims an existing company where the Conversion POC has never logged on
   Given a FEIN for an existing company
   Given Josh is a person who has not logged on
   Given Josh is the staff person for an existing employer
   Given NewGuy is a user with no person who goes to the Employer Portal
    Given NewGuy enters first, last, dob and contact info
    Given NewGuy enters Employer Information
    Then NewGuy becomes an Employer
    When NewGuy decides to Update Business information
    Then Point of Contact count is 2
    And NewGuy logs out 

Scenario: A new person claims an existing company where the Conversion POC has never logged on and matches first, last, dob
   Given a FEIN for an existing company
   Given Josh is a person who has not logged on
   And Josh also has a duplicate person with different DOB
   Given Josh is the staff person for an existing employer
   Given Josh is a user with no person who goes to the Employer Portal
    Given Josh enters info matching the employer staff role
    Given Josh enters Employer Information
    Then Josh becomes an Employer
    When Josh decides to Update Business information
    Then Point of Contact count is 1
    And Josh logs out  

Scenario: A new person claims an existing company where the Conversion POC has never logged on and gives the wrong birthday
   Given a FEIN for an existing company
   Given Josh is a person who has not logged on
   Given Josh is the staff person for an existing employer
   Given Josh is a user with no person who goes to the Employer Portal
    Given Josh matches with different DOB from employer staff role
    Given Josh enters Employer Information
    Then Josh becomes an Employer
    When Josh decides to Update Business information
    Then Point of Contact count is 2
    Then there is a linked POC
    Then there is an unlinked POC
    And Josh logs out             

Scenario: A company  at least one active linked employer staff can delete pending applicant
    Given a FEIN for an existing company
    Given Fred is a person
    Given Fred is the staff person for an existing employer
    Given Sam is a person
    Given Sam is applicant staff person for an existing employer
    When Fred accesses the Employer Portal
    And Fred decides to Update Business information
    Then Point of Contact count is 2
    When Fred removes EmployerStaffRole from Sam
    Then Point of Contact count is 1
