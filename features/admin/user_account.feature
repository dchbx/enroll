Feature: User Account page
  In order for the Hbx admin to access user accounts

  Background: Setup permissions, HBX Admin, users, and organizations and employer profiles
    Given all permissions are present
    And that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And that a user with a Employee Role role exists and is not logged in
    And that a user with a Employer Role role exists and is not logged in
    And that a user with a Broker role exists and is not logged in

  @flaky
  Scenario: Search for Employer by Role filter
    Given user visits the Hbx Portal
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
    Then I should see users with any role

  Scenario: Search for Employer by Locked filter
    Given user with Employee Role role is locked
    And user with Broker role is unlocked
    And user visits the Hbx Portal
    And Hbx Admin click on User Accounts

    When I click Employee and Locked button
    Then I should only see user with employee role

  Scenario: Search for Employer by Unlocked Filter
    Given user with Employee Role role is unlocked
    And user with Broker role is locked
    And user visits the Hbx Portal
    And Hbx Admin click on User Accounts
    When I click Employee and Unlocked button
    Then I should only see user with employee role

  Scenario: Search for User by OIM ID string
    Given user visits the Hbx Portal
    And Hbx Admin click on User Accounts
    Then Hbx Admin should see search box
    When a user enters Employee Role user oim_id in search box
    Then a user should see a result with Employee Role user oim_id and not Broker user oim_id
    When a user enters Employee Role user email
    Then a user should see a result with Employee Role user email and not Broker user email

  Scenario: Should see subrole field on datatable
    And user visits the Hbx Portal
    And Hbx Admin click on User Accounts
    Then I should see subrole field on datatable
