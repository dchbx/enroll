Feature: Employee while terminating active enrollment should able to see and pick termination on kinds dates to terminate

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    Given Qualifying life events are present
    Given Covid QLE present with top ordinal position
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has active benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And employee Patrick Doe has past hired on date

  Scenario Outline: Employee should able to purchase through covid QLE using first_of_this_month effective date and terminates the active enrollment with termination on kinds date
    Given Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    Then Employee should see the "Covid-19" at the top of the shop qle list
    When Employee click the "Covid-19" in qle carousel
    And Employee should see today date and clicks continue
    And Employee select "first_of_this_month" for "covid-19" sep effective on kind and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page with "first_of_this_month" effective date
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the active plan year
    When Patrick Doe selects a plan on the plan shopping page
    Then Employee should see coverage summary page with "first_of_this_month" as coverage effective date
    Then Employee should see receipt page with "first_of_this_month" as coverage effective date
    Then Patrick Doe should see "my account" page with enrollment
    When Patrick Doe clicked on <shopping_button> button
    Then Patrick Doe should see page with SelectPlanToTerminate button
    When Patrick Doe clicks SelectPlanToTerminate button
    Then Patrick Doe should see Termination on kinds dropdown
    When Patrick Doe selects Termination on kinds date on the dropdown
    And Patrick Doe selects active enrollment for termination
    When Patrick Doe submits termination reason in modal
    Then Patrick Doe should see termination confirmation
    Then Patrick Doe should see a confirmation message of Waive Coverage Successful
    And Patrick Doe logs out

    Examples:
      | shopping_button |
      | Shop For Plans  |

  Scenario: Employee should able to purchase through covid QLE using first_of_this_month effective date and terminates the active enrollment with termination on kinds date using Actions drop down
    Given Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    Then Employee should see the "Covid-19" at the top of the shop qle list
    When Employee click the "Covid-19" in qle carousel
    And Employee should see today date and clicks continue
    And Employee select "first_of_this_month" for "covid-19" sep effective on kind and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page with "first_of_this_month" effective date
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the active plan year
    When Patrick Doe selects a plan on the plan shopping page
    Then Employee should see coverage summary page with "first_of_this_month" as coverage effective date
    Then Employee should see receipt page with "first_of_this_month" as coverage effective date
    Then Patrick Doe should see "my account" page with enrollment
    When Employee should be able to see Actions dropdown
    Then Employee clicks on the Actions button
    When Employee clicks on the make changes to my coverage button
    Then Patrick Doe should see page with SelectPlanToTerminate button
    When Patrick Doe clicks SelectPlanToTerminate button
    Then Patrick Doe should see Termination on kinds dropdown
    When Patrick Doe selects Termination on kinds date on the dropdown
    And Patrick Doe selects active enrollment for termination
    When Patrick Doe submits termination reason in modal
    Then Patrick Doe should see termination confirmation
    Then Patrick Doe should see a confirmation message of Waive Coverage Successful
    And Patrick Doe logs out
