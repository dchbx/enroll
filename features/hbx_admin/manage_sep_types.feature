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
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Individual tab
    Then Admin should see listed Individual market sep types with ascending ordinal positions
    When Admin sorts Individual sep types by drag and drop
    Then Admin should see successful message after sorting
    And listed Individual sep types ordrinal postions should change
    When Admin clicks on Shop tab
    Then Admin should see listed Shop market sep types with ascending ordinal positions
    When Admin sorts Shop sep types by drag and drop
    Then Admin should see successful message after sorting
    And listed Shop sep types ordrinal postions should change
    When Admin clicks on Congress tab
    Then Admin should see listed Congress market sep types with ascending ordinal positions
    When Admin sorts Congress sep types by drag and drop
    Then Admin should see successful message after sorting
    And listed Congress sep types ordrinal postions should change
    And Hbx Admin logs out
