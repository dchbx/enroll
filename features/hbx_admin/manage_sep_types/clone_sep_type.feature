Feature: Admin has ability to Clone the Active/InActive SEP Type
  Background:
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEP Types under admin dropdown
    And Admin can click Manage SEP Types link

  Scenario Outline: Admin can clone an Active <market_kind> market SEP type
    Given Admin can navigate to the Manage SEP Types screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Active filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin can see Clone button
    When Admin clicks on Clone button of an Active SEP Type
    Then Admin navigates to Create SEP Type page
    And Admin fills Create SEP Type form with start and end dates
    And Admin should see Title field filled with title
    And Admin should see Event label field filled with event label
    And Admin should see Tool Tip field filled with tool tip
    And Admin should see Reason field filled with reason
    And Admin should see <market_kind> market radio button selected
    And Admin should see Pre Event Sep In Days field filled with days
    And Admin should see Post Event Sep In Days field filled with days
    And Admin should see effective on kinds checked based on <market_kind>
    And Admin <term_action> select termination on kinds for <market_kind> SEP Type
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    And Hbx Admin logs out

    Examples:
      | market_kind | term_action |
      | individual  | cannot      |
      | shop        |  can        |
      | fehb        |  can        |

  Scenario Outline: Admin can clone an InActive <market_kind> market SEP type
    Given Admin can navigate to the Manage SEP Types screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Inactive filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin can see Clone button
    When Admin clicks on Clone button of an Active SEP Type
    Then Admin navigates to Create SEP Type page
    And Admin fills Create SEP Type form with start and end dates
    And Admin should see Title field filled with title
    And Admin should see Event label field filled with event label
    And Admin should see Tool Tip field filled with tool tip
    And Admin should see Reason field filled with reason
    And Admin should see <market_kind> market radio button selected
    And Admin should see Pre Event Sep In Days field filled with days
    And Admin should see Post Event Sep In Days field filled with days
    And Admin should see effective on kinds checked based on <market_kind>
    And Admin <term_action> select termination on kinds for <market_kind> SEP Type
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    And Hbx Admin logs out

    Examples:
      | market_kind | term_action |
      | individual  | cannot      |
      | shop        |  can        |
      | fehb        |  can        |

  Scenario Outline: Admin can see clone action button for Active SEP type
    Given Admin can navigate to the Manage SEP Types screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Active filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin <action> see Clone button
    And Hbx Admin logs out

    Examples:
      | market_kind  |  action    |
      | individual   |  can       |
      | shop         |  can       |
      | fehb         |  can       |

  Scenario Outline: Admin can see clone action button for InActive SEP type
    Given Admin can navigate to the Manage SEP Types screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Inactive filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin <action> see Clone button
    And Hbx Admin logs out

    Examples:
      | market_kind  |  action    |
      | individual   |  can       |
      | shop         |  can       |
      | fehb         |  can       |

  Scenario Outline: Admin can't see clone action button for Draft SEP type
    Given Admin can navigate to the Manage SEP Types screen
    And draft Qualifying life events of <market_kind> market is present
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Draft filter of <market_kind> market filter
    When Hbx Admin clicks Action button
    Then Admin <action> see Clone button
    And Hbx Admin logs out

    Examples:
      | market_kind  |  action    |
      | individual   |  cannot    |
      | shop         |  cannot    |
      | fehb         |  cannot    |
