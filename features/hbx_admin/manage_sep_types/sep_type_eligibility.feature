Feature: Qualifying life of event kind based on eligibity dates
  Background:
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    And Hbx Admin logs on to the Hbx Portal
    And the Admin is on the Main Page
    And the FAA feature configuration is enabled

  Scenario: Consumer qualify for Special enrollment period based on eligibity dates
    Given Hbx Admin Creates and Publish Individual market SEP Type
    And Hbx Admin logs out
    Given Individual creates account and on home page
    And Individual should see listed individual market SEP Types
    And Individual should see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    When Individual click on the "Entered into a legal domestic partnership" Sep Type
    And Individual should see input field to enter the Sep Type date
    And Individual fill in QLE date within the range eligiblity date period
    And Individual should see QLE date filled and clicks continue
    Then Individual should see sucess confirmation text
    When Individual click on the "Entered into a legal domestic partnership" Sep Type
    And Individual should see input field to enter the Sep Type date
    And Individual fill in QLE date outside the range eligiblity date period
    And Individual should see QLE date filled and clicks continue
    Then Individual should not see sucess confirmation text
    And I click on log out link

  Scenario: Admin logged to qualify consumer for special enrollment period based on eligibity dates
    Given Hbx Admin Creates and Publish Individual market SEP Type
    And Hbx Admin logs out
    Given Individual creates account and on home page
    And I click on log out link
    And Hbx Admin logs on to the Hbx Portal
    When Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And Admin clicks name of a ivl family person on the family datatable
    Then I should land on home page
    And I should see listed individual market SEP Types
    And I should see the "Entered into a legal domestic partnership" at the bottom of the ivl qle list
    When I click on the "Entered into a legal domestic partnership" Sep Type
    And I should see input field to enter the Sep Type date
    And I fill in QLE date within the range eligiblity date period
    And I should see QLE date filled and clicks continue
    Then I should see sucess confirmation text
    When Admin click on the "Entered into a legal domestic partnership" Sep Type
    And Admin should see input field to enter the Sep Type date
    And Admin fill in QLE date outside the range eligiblity date period
    And Admin should see QLE date filled and clicks continue
    Then Admin should not see sucess confirmation text
    And Admin logs out

  Scenario: Employee qualify for Special enrollment period based on eligibity dates
    Given Hbx Admin Creates and Publish Shop market SEP Type
    And Hbx Admin logs out
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has active benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And employee Patrick Doe has past hired on date
    Given Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    Then Employee should see the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    When Employee click on the "Entered into a legal domestic partnership" Sep Type
    And Employee should see input field to enter the Sep Type date
    And Employee fill in QLE date within the range eligiblity date period
    And Employee should see QLE date filled and clicks continue
    Then Employee should see sucess confirmation text
    When Employee click on the "Entered into a legal domestic partnership" Sep Type
    And Employee should see input field to enter the Sep Type date
    And Employee fill in QLE date outside the range eligiblity date period
    And Employee should see QLE date filled and clicks continue
    Then Employee should not see sucess confirmation text
    And Employee logs out

  Scenario: Admin logged to qualify employee for special enrollment period based on eligibity dates
    Given Hbx Admin Creates and Publish Shop market SEP Type
    And Admin logs out
    Given Employee creates account and on home page
    And Employee logs out
    And Hbx Admin logs on to the Hbx Portal
    When Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And Admin clicks name of a shop family person on the family datatable
    Then I should land on home page
    And I should see listed shop market SEP Types
    And I should see the "Entered into a legal domestic partnership" at the bottom of the shop qle list
    When I click on the "Entered into a legal domestic partnership" Sep Type
    And I should see input field to enter the Sep Type date
    And I fill in QLE date within the range eligiblity date period
    And I should see QLE date filled and clicks continue
    Then I should see sucess confirmation text
    When Admin click on the "Entered into a legal domestic partnership" Sep Type
    And Admin should see input field to enter the Sep Type date
    And Admin fill in QLE date outside the range eligiblity date period
    And Admin should see QLE date filled and clicks continue
    Then Admin should not see sucess confirmation text
    And Admin logs out
