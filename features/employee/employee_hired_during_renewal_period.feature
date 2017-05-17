Feature: Employee hired during renewal period
  In order for the New Employee to purchase insurance
  Given Employer is a Renewing Employer
  Given New Employee is on the Census Employee Roster
  Given New Employee does not have a pre-existing person
  Then New Employee should be able to match Employer
  And Employee should be able to purchase Insurance

  Scenario: New hire should be able to purchase Insurance under current plan year

    Given Renewing Employer for Soren White exists with active and renewing plan year
      And Employer for Soren White is under open enrollment
      And Employer for Soren White has first_of_month rule
      And Employee has current hired on date
      And Soren White already matched and logged into employee portal
      When Employee clicks "Shop for Plans" on my account page
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      And I should not see any plan which premium is 0
      When Employee selects a plan on the plan shopping page
      Then Employee Soren White should see coverage effective date
      When Employee clicks on Confirm button on the coverage summary page
      Then Employee should see the receipt page
      Then Employee clicks on Continue button on receipt page
      Then Soren White should see "my account" page with active enrollment
      And Soren White should see passive renewal

