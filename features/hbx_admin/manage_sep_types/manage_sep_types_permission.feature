Feature: Admin can manage SEP Types like create, sort, update and expire
  
  Scenario Outline: HBX Staff with <subrole> subroles should <action> Manage SEP Types button
    Given that a user with a HBX staff role with <subrole> subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And Qualifying life events of all markets are present
    And the Admin will <action> the Manage SEP Types under admin dropdown
    And Admin <subaction> click Manage SEP Types link
    Then Admin <subaction> navigate to the Manage SEP Types screen
    And Hbx Admin logs out

    Examples:
      | subrole       | action  | subaction  |
      | super_admin   | see     |   can      |
      | hbx_tier3     | see     |   can      |
      | hbx_staff     | not see |   cannot   |
      | hbx_read_only | not see |   cannot   |
      | developer     | not see |   cannot   |
