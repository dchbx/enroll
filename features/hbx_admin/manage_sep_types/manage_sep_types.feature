Feature: Admin need permission to see Manage SEPs link and active SEP Types on Datable
  
  Scenario Outline: HBX Staff with <subrole> subroles should <action> Manage SEPs button
    Given that a user with a HBX staff role with <subrole> subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will <action> the Manage SEPs under admin dropdown
    And Admin <subaction> click Manage SEPs link
    Then Admin <subaction> navigate to the Manage SEPs screen
    And Hbx Admin logs out

    Examples:
      | subrole       | action  | subaction  |
      | super_admin   | see     |   can      |
      | hbx_tier3     | see     |   can      |
      | hbx_staff     | not see |   cannot   |
      | hbx_read_only | not see |   cannot   |
      | developer     | not see |   cannot   |

  Scenario Outline: Admin should able to see Active <market_kind> market SEP Types on datatable
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    When Admin can click Manage SEPs link
    Then Admin can navigate to the Manage SEPs screen
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Active filter of <market_kind> market filter
    Then Admin should see listed Active <market_kind> market SEP Types on datatable
    And Hbx Admin logs out

  Examples:
    | market_kind |
    | individual  |
    | shop        |
    | fehb        |
