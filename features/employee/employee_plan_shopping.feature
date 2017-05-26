Feature: Employees can purchase coverage from both active and renewing plan years if they are eligible
  Employees are blocked in the middle of plan shopping if they are not eligible
  and allowing them to complete plan shopping if they are eligible

  Scenario: Employee can buy coverage under previous expired plan year using QLE if he is eligible
    Given Congressional Employer for Soren White exists with active and expired plan year
      And Employee has past hired on date
      And Soren White already matched and logged into employee portal
      When Employee click the "Had a baby" in qle carousel
      And Employee select a qle date based on expired plan year
      Then Employee should see confirmation and clicks continue
      Then Employee should see family members page and clicks continue
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      And Soren White should see the plans from the expired plan year
      When Employee selects a plan on the plan shopping page
      Then Soren White should see coverage summary page with qle effective date
      Then Soren White should see the receipt page with qle effective date as effective date
      Then Soren White should see "my account" page with enrollment

  Scenario: Employee can buy coverage from active plan year through qle with active plan year's plans in renewal period
    Given Congressional Employer for Soren White exists with active and renewing enrolling plan year
      And Employee has past hired on date
      And Soren White already matched and logged into employee portal
      When Employee click the "Had a baby" in qle carousel
      And Employee select a past qle date
      Then Employee should see confirmation and clicks continue
      Then Employee should see family members page and clicks continue
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      And Soren White should see the plans from the active plan year
      When Employee selects a plan on the plan shopping page
      Then Soren White should see coverage summary page with qle effective date
      Then Soren White should see the receipt page with qle effective date as effective date
      Then Soren White should see "my account" page with enrollment


  Scenario: Employee should be blocked from plan shopping if their eligibility date greater than their effective date
    Given Congressional Employer for Soren White exists with active and renewing enrolling plan year
      And Employee has current hired on date
      And Soren White already matched and logged into employee portal
      When Employee click the "Had a baby" in qle carousel
      And Employee select a past qle date
      Then Employee should see confirmation and clicks continue
      Then Employee should see family members page and clicks continue
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see "You are attempting to purchase coverage through qle proir to your eligibility date" error message
    