Feature: User Account page
  In order for the Hbx admin to access user accounts

  Scenario: Successful attempt to Search for an employer
    Given a Hbx admin with read and write permissions and employers
    And a user exists with employer staff role
    And a user exists with employee role
    And a user exists with broker role
    When Hbx AdminEnrollments logs on to the Hbx Portal
    And Hbx Admin click on User Accounts
    Then Hbx Admin should see text Account Updates
    Then Hbx Admin should see columns related to user account
    Then Hbx Admin should see buttons to filter
    When I click Employee button
    Then I should only see user with employee role
    When I click Employer button
    Then I should only see user with employer staff role
    When I click Broker button
    Then I should only see user with broker role
    When I click All button
    Then I should only see user with all roles

    Given a locked user exists with employer staff role
    And a locked user exists with employee role
    And a locked user exists with broker role
    
    When I click Employee and Locked button
    Then I should only see locked user with employee role
    When I click Employee and Unlocked button
    Then I should only see unlocked user with employee role
    
  Scenario: Search for an user
    Given a Hbx admin with read and write permissions and employers
    And a user exists with employer staff role
    And a user exists with employee role
    And a user exists with broker role
    When Hbx AdminEnrollments logs on to the Hbx Portal
    And Hbx Admin click on User Accounts
    Then Hbx Admin should see search box
    When a user enters an user name search box
    Then a user should see a result with the user name
    When a user enter person hbx id
    Then a user should see a result with hbx id

