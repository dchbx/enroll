Feature: Admin has ability to sort SEP Types and the positions of SEPs will reflect on the user and hbx portal home page qle carousel to plan shop
  Background:
    Given a Hbx admin with hbx_tier3 permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    And Qualifying life events of all markets are present
    And the user will see the Manage SEP Types under admin dropdown
    When Admin clicks Manage SEP Types

  Scenario: Admin will sort Individual market SEP Types and it will reflect the same order on the individual insured home page qle carousel
    Given the Admin is navigated to the Manage SEP Types screen
    When Admin clicks on the Sorting SEP Types button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Individual tab
    Then Admin should see listed Individual market SEP Types with ascending ordinal positions
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
    And I should see listed Individual market SEP Types
    And I should see the "Had a baby" at the top of the ivl qle list
    And I click on log out link
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    And the user will see the Manage SEP Types under admin dropdown
    When Admin clicks Manage SEP Types
    Given the Admin is navigated to the Manage SEP Types screen
    When Admin clicks on the Sorting SEP Types button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Individual tab
    Then Admin should see listed Individual market SEP Types with ascending ordinal positions
    When Admin sorts Individual SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Individual SEP Types ordinal postions should change
    And Hbx Admin logs out
    Then Individual resumes enrollment
    And I click on sign in existing account
    And I signed in
    Then I should land on home page
    Then I should see the "Married" at the top of the ivl qle list
    Then Individual logs out

  Scenario: Admin will sort Shop market SEP Types and it will reflect the same order on the employee home page qle carousel
    Given the Admin is navigated to the Manage SEP Types screen
    When Admin clicks on the Sorting SEP Types button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Shop tab
    Then Admin should see listed Shop market SEP Types with ascending ordinal positions
    And Hbx Admin logs out
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has active benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And employee Patrick Doe has past hired on date
    Given Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    Then Employee should see the "Covid-19" at the top of the shop qle list
    Then Employee logs out
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    And the user will see the Manage SEP Types under admin dropdown
    When Admin clicks Manage SEP Types
    Given the Admin is navigated to the Manage SEP Types screen
    When Admin clicks on the Sorting SEP Types button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on Shop tab
    Then Admin should see listed Shop market SEP Types with ascending ordinal positions
    When Admin sorts Shop SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Shop SEP Types ordinal postions should change
    And Hbx Admin logs out
    When employee visits the Employee Portal page
    And Employee signed in
    Then Employee should land on home page
    And Employee should see the "Married" at the top of the shop qle list
    Then Employee logs out
