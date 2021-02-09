Feature: Employee hired during renewal period
    In order for the New Employee to purchase insurance
    Given Employer is a Renewing Employer
    Given New Employee is on the Census Employee Roster
    Given New Employee does not have a pre-existing person
    Then New Employee should be able to match Employer
    And Employee should be able to purchase Insurance

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And this employer offering 0.75 contribution to Employee
    And this employer ABC Widgets has first_of_month rule

  Scenario: New hire should be able to purchase Insurance under current plan year & should be able to
    purchase coverage by clicking on make_changes button on passive renewal

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    When Employee clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And I should not see any plan which premium is 0
    When Employee selects a plan on the plan shopping page
    Then Employee Patrick Doe should see coverage effective date
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee clicks on Continue button on receipt page
    Then Patrick Doe should see "my account" page with active enrollment
    And Patrick Doe should see passive renewal
    When Employee should be able to see Actions dropdown
    Then Employee clicks on the Actions button
    When Employee clicks on the make changes to my coverage button
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And I should not see any plan which premium is 0
    When Employee selects a plan on the plan shopping page
    Then Employee Patrick Doe should see confirm your plan selection page
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee clicks on Continue button on receipt page
    Then Patrick Doe should see "my account" page with active enrollment
    And Patrick Doe should see renewal policy in active status
