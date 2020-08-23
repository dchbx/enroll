Feature: When Admin visits SEP Details page
  Background:
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  Scenario Outline: Admin should see disabled form
    Given Admin can navigate to the Manage SEPs screen
    And Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Active filter of <market_kind> market filter
    Then Admin clicks on Active SEP Type title for <market_kind> on Datatable
    When Admin navigates to SEP Type Details page
    When Admin should see Title field disabled
    When Admin should see Event label field disabled
    When Admin should see Tool Tip field disabled
    When Admin should see Reason field disabled
    When Admin should see <market_kind> market radio button disabled
    When Admin should see Pre Event Sep In Days field disabled
    When Admin should see Post Event Sep In Days field disabled
    When Admin should see effective on kinds disabled for <market_kind>
    And Hbx Admin logs out

    Examples:
      | market_kind |
      | individual  |
      | shop        |
      | fehb        |
