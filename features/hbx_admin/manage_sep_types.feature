Feature: Admin can manage sep types like create, edit, update, delete and sort
  Background:
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    Given Qualifying life events of all markets are present
    And the user will see the Manage Sep Types under admin dropdown
    When Admin clicks Manage Sep Types
    
  Scenario: Navigate to Manage Sep Types screen
    When the Admin is navigated to the Manage Sep Types screen
    Then the Admin has the ability to use the following filters for documents provided: All, Individual, Shop and Congress
    And Hbx Admin logs out

  Scenario: Admin has ability to sort the sep types and saves the ordinal positions to the database
    Given the Admin is navigated to the Manage Sep Types screen
    When Admin will click on the Sorting Sep Types button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Individual tab
    Then Admin should see listed Individual market sep types with ascending ordinal positions
    When Admin sorts Individual sep types by drag and drop
    Then Admin should see successful message after sorting
    And listed Individual sep types ordrinal postions should change
    When Admin clicks on Shop tab
    Then Admin should see listed Shop market sep types with ascending ordinal positions
    When Admin sorts Shop sep types by drag and drop
    Then Admin should see successful message after sorting
    And listed Shop sep types ordrinal postions should change
    When Admin clicks on Congress tab
    Then Admin should see listed Congress market sep types with ascending ordinal positions
    When Admin sorts Congress sep types by drag and drop
    Then Admin should see successful message after sorting
    And listed Congress sep types ordrinal postions should change
    And Hbx Admin logs out

  Scenario: Admin on sorting Individual market sep types will reflect the same order on the individual insured home page qle carousel
    Given the Admin is navigated to the Manage Sep Types screen
    When Admin will click on the Sorting Sep Types button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Individual tab
    Then Admin should see listed Individual market sep types with ascending ordinal positions
    And Hbx Admin logs out
    Given Individual has not signed up as an HBX user
    When Individual with known qles visits the Insured portal outside of open enrollment
    Then Individual creates a new HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    And Individual click on sign in existing account
    And I signed in
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And I click on continue button on household info form
    When I click on none of the situations listed above apply checkbox
    And I click on back to my account button
    Then I should land on home page
    And I should see listed Individual market sep types
    And I should see the "Had a baby" at the top of the ivl qle list
    And I click on log out link
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    And the user will see the Manage Sep Types under admin dropdown
    When Admin clicks Manage Sep Types
    Given the Admin is navigated to the Manage Sep Types screen
    When Admin will click on the Sorting Sep Types button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Individual tab
    Then Admin should see listed Individual market sep types with ascending ordinal positions
    When Admin sorts Individual sep types by drag and drop
    Then Admin should see successful message after sorting
    And listed Individual sep types ordrinal postions should change
    And Hbx Admin logs out
    Then Individual resumes enrollment
    And I click on sign in existing account
    And I signed in
    Then I should land on home page
    Then I should see the "Married" at the top of the ivl qle list
    Then Individual logs out
