Feature: Add searchbox on broker agencies
  In order for the Hbx admin to search for broker agencies through searchbox

  Scenario: Search for a broker agency
    Given a Hbx admin with read and write permissions and broker agencies
    When Hbx AdminEnrollments logs on to the Hbx Portal
    And Hbx Admin click on Broker Agencies 
    Then Hbx Admin should see searchbox
    When he enters an broker agency name and clicks on the search button
    Then he should see the one result with the agency name 
