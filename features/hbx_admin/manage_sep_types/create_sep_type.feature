Feature: Admin has ability to create a new SEP Type
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
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin clicks reason drop down on Create SEP type form
    And Admin selects expired reason from drop down on Create SEP type form
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks <market_kind> filter on SEP Types datatable
    And clicks on Draft filter of <market_kind> market filter
    Then Admin should see newly created SEP Type title on Datatable
    And Hbx Admin logs out

  Examples:
    | market_kind | action |
    | individual  | cannot |
    | shop        |  can   |
    | fehb        |  can   |

  Scenario Outline: Failure scenario to create <market_kind> market SEP type
    Given Admin can navigate to the Manage SEP Types screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start on date greater than end on date
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin clicks reason drop down on Create SEP type form
    And Admin selects expired reason from drop down on Create SEP type form
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see failure reason while creating a new SEP Type
    And Hbx Admin logs out

  Examples:
    | market_kind | action |
    | individual  | cannot |
    | shop        |  can   |
    | fehb        |  can   |
