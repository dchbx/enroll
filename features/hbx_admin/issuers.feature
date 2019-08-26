Feature: Users can view carriers and its associated products based on sbc_role.
  Scenario: Hbx Admin views products
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin has access to the Issuers tab
    And Hbx Admin clicks on Issuers tab
    When Hbx Admin click on a carrier
    Then Hbx Admin should see a list of products

  Scenario: Hbx Admin Tier 3 views products
    Given Hbx Admin Tier 3 exists
    When Hbx Admin Tier 3 logs on to the Hbx Portal
    Then Hbx Admin Tier 3 does not have access to the Issuers tab
