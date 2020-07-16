Feature: Admin can manage sep types like create, edit, update, delete and sort
  Background:
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    Given Qualifying life events of all markets are present
    And the user will see the Manage Sep Types under admin dropdown
    When Admin clicks Manage Sep Types
    
  Scenario: Navigate to Manage Sep Types screen
    When the Admin is navigated to the Manage Sep Types screen
    Then the Admin has the ability to use the following filters for documents provided: All, Individual, Shop and Congress
    And Hbx Admin logs out

  Scenario: Admin has ability to sort the sep types and save the positions to the database
    Given the Admin is navigated to the Manage Sep Types screen
    When Admin will click on the Sorting Sep Types button
    Then Admin will see three tabs Individual, Shop and Congress markets
    And Admin will sort Individual market sep types
    Then Admin should see successful message after sorting
    And Hbx Admin logs out
