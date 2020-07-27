Feature: Admin has ability to Expire the Active SEP Type
  Background:
    Given a Hbx admin with hbx_tier3 permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    And Qualifying life events of all markets are present
    And the user will see the Manage SEP Types under admin dropdown
    When Admin clicks Manage SEP Types

  Scenario Outline: Admin will create a new <market_kind> SEP type
    Given the Admin is navigated to the Manage SEP Types screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And clicks on Active filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin should see Expire dropdown button
    When Admin clicks on Expire button of an Active SEP Type
    And Admin changes the end on date of an Active SEP Type to expire 
    And Admin clicks on Expire button
    Then Admin Should see a successful flash message of an Expire
    And Hbx Admin logs out

  Examples:
    | market_kind | action |
    | individual  | cannot |
    | shop        |  can   |
    | fehb        |  can   |