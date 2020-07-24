Feature: Admin has ability to create a new SEP type for users
  Background:
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    Given Qualifying life events of all markets are present
    And the user will see the Manage SEP Types under admin dropdown
    When Admin clicks Manage SEP Types

  Scenario: Admin will create a new SEP type
    Given the Admin is navigated to the Manage SEP Types screen
    When Admin clicks on the Create SEP Type button
    And Admin navigates on Create SEP Type page
    And Admin fill the form page
