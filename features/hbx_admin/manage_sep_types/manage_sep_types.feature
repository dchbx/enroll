Feature: Admin can manage SEP Types like create, edit, update, delete and sort
  Background:
    Given a Hbx admin with hbx_tier3 permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    And Qualifying life events of all markets are present
    And the user will see the Manage SEP Types under admin dropdown
    When Admin clicks Manage SEP Types

  Scenario: Navigate to Manage SEP Types screen
    When the Admin is navigated to the Manage SEP Types screen
    Then the Admin has the ability to use the following filters for documents provided: All, Individual, Shop and Congress
    And Admin should see sorting SEP Types button and create SEP Type button
    And Hbx Admin logs out

  Scenario: Admin has ability to sort the SEP Types and saves the ordinal positions to the database
    Given the Admin is navigated to the Manage SEP Types screen
    When Admin clicks on the Sorting SEP Types button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Individual tab
    Then Admin should see listed Individual market SEP Types with ascending ordinal positions
    When Admin sorts Individual SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Individual SEP Types ordinal postions should change
    When Admin clicks on Shop tab
    Then Admin should see listed Shop market SEP Types with ascending ordinal positions
    When Admin sorts Shop SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Shop SEP Types ordinal postions should change
    When Admin clicks on Congress tab
    Then Admin should see listed Congress market SEP Types with ascending ordinal positions
    When Admin sorts Congress SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Congress SEP Types ordinal postions should change
    When Admin clicks on List SEP Types link
    Then Admin navigates to SEP Type List page
    And Hbx Admin logs out
