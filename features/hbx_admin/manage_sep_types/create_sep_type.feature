Feature: Admin has ability to create a new SEP Type
  Background:
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  Scenario Outline: Admin will create a new <market_kind> SEP type
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Draft filter of <market_kind> market filter
    Then Admin should see newly created SEP Type title on Datatable
    And Hbx Admin logs out

  Examples:
    | market_kind | action |
    | individual  | cannot |
    | shop        |  can   |
    | fehb        |  can   |

  Scenario Outline: Failure scenario to create <market_kind> market SEP type
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start on date greater than end on date
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see failure for end date
    And Hbx Admin logs out

  Examples:
    | market_kind | action |
    | individual  | cannot |
    | shop        |  can   |
    | fehb        |  can   |


  Scenario Outline: Admin will create a new <market_kind> SEP type with/without selecting termination on kinds
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> termination on kinds for <market_kind> market
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Draft filter of <market_kind> market filter
    Then Admin should see newly created SEP Type title on Datatable
    And Hbx Admin logs out

    Examples:
      | market_kind | action          |
      | shop        |  selected       |
      | fehb        |  selected       |
      | shop        |  not selected   |
      | fehb        |  not selected   |

  Scenario: Admin should see failure when creating SEP type with past start date
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with past start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects individual market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see failure for start date
    And Hbx Admin logs out

  Scenario: Admin should see failure when creating SEP type with invalid eligibity date
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects individual market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin fills invalid eligibility start and end dates
    And Admin clicks on Create Draft button
    Then Admin should see failure for invalid eligibility date
    And Hbx Admin logs out

  Scenario: Admin should see failure when creating SEP type withonly eligibility start date
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects individual market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin fills eligibility start date
    And Admin clicks on Create Draft button
    Then Admin should see failure for eligibility end date
    And Hbx Admin logs out

  Scenario: Admin should see failure when creating SEP type withonly eligibility end date
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects individual market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin fills eligibility end date
    And Admin clicks on Create Draft button
    Then Admin should see failure for eligibility start date
    And Hbx Admin logs out