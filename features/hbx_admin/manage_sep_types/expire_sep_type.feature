Feature: Admin has ability to Expire the Active SEP Type
  Background:
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  Scenario Outline: Admin will expire an Active <market_kind> market SEP type
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Active filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin should see Expire dropdown button
    When Admin clicks on Expire button of an Active SEP Type
    And Admin changes the end on date of an Active SEP Type to expire 
    And Admin clicks on Expire button
    Then Admin should see a successful message of an Expire
    And Hbx Admin logs out

  Examples:
    | market_kind |
    | individual  |
    | shop        |
    | fehb        |

  Scenario Outline: Admin will get failure reason while expiring an Active <market_kind> market SEP type with end date earlier than start date
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Active filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin should see Expire dropdown button
    When Admin clicks on Expire button of an Active SEP Type
    And Admin fills end on date earlier than start on date of an Active SEP Type
    And Admin clicks on Expire button
    Then Admin should see a failure reason of an Expire
    And Hbx Admin logs out

  Examples:
    | market_kind |
    | individual  |
    | shop        |
    | fehb        |

  Scenario Outline: Admin will get failure reason while expiring an Active <market_kind> market SEP type with past end date
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Active filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin should see Expire dropdown button
    When Admin clicks on Expire button of an Active SEP Type
    And Admin fills end on with past date
    And Admin clicks on Expire button
    Then Admin should see failure reason for past date of an Expire
    And Hbx Admin logs out

    Examples:
      | market_kind |
      | individual  |
      | shop        |
      | fehb        |

  Scenario Outline: Admin should able to expire Active <market_kind> market SEP type with yesterday date
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Active filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin should see Expire dropdown button
    When Admin clicks on Expire button of an Active SEP Type
    And Admin fills end on with yesterday date
    And Admin clicks on Expire button
    Then Admin should see a Expired successful message
    And Hbx Admin logs out

    Examples:
      | market_kind |
      | individual  |
      | shop        |
      | fehb        |