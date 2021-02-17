@flaky
Feature:  Employee passive renewal should be canceled when Employee waived coverage
  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And this employer offering 0.75 contribution to Employee
    And this employer ABC Widgets has first_of_month rule

  @flaky
  Scenario: Renewing employee waive coverage
    Given there exists Patrick Doe employee for employer ABC Widgets
      And employee Patrick Doe has current hired on date
      And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
      When Employee clicks "Shop for Plans" on my account page
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      And I should not see any plan which premium is 0
      When Employee selects waiver on the plan shopping page
      When Employee submits waiver reason
      Then Employee should see waiver summary page 
      When Employee clicks continue on waiver summary page
      Then Employee should able to see Waiver tile