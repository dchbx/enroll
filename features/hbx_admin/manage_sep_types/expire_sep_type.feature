Feature: Admin has ability to Expire the Active SEP Type
  Background:
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEP Types under admin dropdown
    And Admin can click Manage SEP Types link

  Scenario Outline: Admin will create a new <market_kind> SEP type
    Given Admin can navigate to the Manage SEP Types screen
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