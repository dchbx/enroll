Feature: Admin can see Hub response
  User should have the role of an admin
  Admin can go to IVL consumer Documents page
  Admin can see detailed result of SSA DHS hub responses

  Scenario: Admin check IVL consumer documents page
    Given Hbx Admin exists
    And Family with unverified family members and enrollment
    And Every family member has SSA and DHS response
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin clicks on the Documents tab
    Then Admin schould see list of primary applicants with unverified family
    When Hbx Admin clicks on the Review button
    Then Admin goes to Documents page for this consumer account
    When Admin click on FedHub tab
    Then Admin should see table with Hub response details
    And Parsed response from SSA hub
    And Parsed response from DHS hub

