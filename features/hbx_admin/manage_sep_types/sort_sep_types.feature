Feature: Admin has ability to sort SEP Types on Sort SEPs Page and save their positions in DB
  User will create an account through HBx Portal to sign as Consumer and checks the re arranged positions of SEP Type on Qle carousel
  User will create an account through HBx Portal to sign as Employee and checks the re arranged positions of SEP Type on Qle carousel

  Background:
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And the FAA feature configuration is enabled
    And Qualifying life events of all markets are present
    And the Admin will see the Manage SEPs under admin dropdown
    And Admin can click Manage SEPs link

  @flaky
  Scenario: Admin has ability to sort the SEP Types and saves the positions to the database
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on individual tab
    Then Admin should see listed individual market SEP Types with ascending positions
    When Admin sorts Individual SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Individual SEP Types ordinal postions should change
    When Admin clicks on shop tab
    Then Admin should see listed shop market SEP Types with ascending positions
    When Admin sorts Shop SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Shop SEP Types ordinal postions should change
    When Admin clicks on congress tab
    Then Admin should see listed congress market SEP Types with ascending positions
    When Admin sorts Congress SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Congress SEP Types ordinal postions should change
    When Admin clicks on List SEP Types link
    Then Admin navigates to SEP Type List page
    And Hbx Admin logs out

  @flaky
  Scenario: Admin will sort Individual market SEP Types and it will reflect the same order on the individual insured home page qle carousel
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on individual tab
    Then Admin should see listed individual market SEP Types with ascending positions
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
    And Individual click on Sign In
    And I signed in
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should be on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    Then Individual should see the dependents form
    And I click on continue button on household info form
    When I click on none of the situations listed above apply checkbox
    And I click on back to my account button
    Then I should land on home page
    And I should see listed individual market SEP Types
    And I should see the "Had a baby" at the top of the ivl qle list
    And I click on log out link
    When Hbx Admin logs on to the Hbx Portal
    Given the Admin is on the Main Page
    And the Admin will see the Manage SEPs under admin dropdown
    When Admin can click Manage SEPs link
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on individual tab
    Then Admin should see listed individual market SEP Types with ascending positions
    When Admin sorts Individual SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Individual SEP Types ordinal postions should change
    And Hbx Admin logs out
    Then Individual resumes enrollment
    And I click on Sign In
    And I signed in
    Then I should land on home page
    Then I should see the "Married" at the top of the ivl qle list
    Then Individual logs out

  Scenario: Admin will create a new Individual market SEP type with future date and try to sort the Sep Type
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of individual market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with future start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects individual market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin cannot select termination on kinds for individual SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks individual filter on SEP Types datatable
    And Admin clicks on Draft filter of individual market filter
    Then Admin should see newly created SEP Type title on Datatable
    When Admin clicks on newly created SEP Type
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see Successfully publish message
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on individual tab
    And Admin should see listed individual market SEP Types
    And Admin should not see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    And Hbx Admin logs out

  Scenario: Admin will sort Shop market SEP Types and it will reflect the same order on the employee home page qle carousel
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on shop tab
    Then Admin should see listed Active shop market SEP Types on datatable
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
    Given the Admin is on the Main Page
    And the Admin will see the Manage SEPs under admin dropdown
    When Admin can click Manage SEPs link
    Given Admin can navigate to the Manage SEPs screen
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    Then Admin should see listed individual market SEP Types with ascending positions
    When Admin sorts Individual SEP Types by drag and drop
    Then Admin should see successful message after sorting
    When Admin clicks on shop tab
    Then Admin should see listed shop market SEP Types with ascending positions
    When Admin sorts Shop SEP Types by drag and drop
    Then Admin should see successful message after sorting
    And listed Shop SEP Types ordinal postions should change
    And Hbx Admin logs out
    When employee visits the Employee Portal page
    And Employee signed in
    Then Employee should land on home page
    And Employee should see the "Married" at the top of the shop qle list
    Then Employee logs out

  Scenario: Admin will create a new Shop market SEP type with future date and try to sort the Sep Type
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of shop market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with future start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects shop market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin can select termination on kinds for shop SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks shop filter on SEP Types datatable
    And Admin clicks on Draft filter of shop market filter
    Then Admin should see newly created SEP Type title on Datatable
    When Admin clicks on newly created SEP Type
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see Successfully publish message
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on shop tab
    And Admin should see listed shop market SEP Types
    And Admin should not see the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    And Hbx Admin logs out

  Scenario Outline: Admin will create a new <market_kind> SEP type and publish it
    Given Admin can navigate to the Manage SEPs screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with future start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button
    And Admin fills Create SEP Type form with Reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks <market_kind> filter on SEP Types datatable
    And Admin clicks on Draft filter of <market_kind> market filter
    Then Admin should see newly created SEP Type title on Datatable
    When Admin clicks on newly created SEP Type
    Then Admin should navigate to update SEP Type page
    When Admin clicks on Publish button
    Then Admin should see Successfully publish message
    When Admin clicks on the Sort SEPs button
    Then Admin should see three tabs Individual, Shop and Congress markets
    When Admin clicks on <market_kind> tab
    Then Admin should see listed <market_kind> market SEP Types
    And Admin should see the Entered into a legal domestic partnership in the <market_kind> qle list
    And Hbx Admin logs out

    Examples:
      | market_kind | action |
      | individual  | cannot |
      | shop        | can    |
      | fehb        | can    |
