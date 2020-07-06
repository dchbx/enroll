Feature: Employees can purchase coverage from both active and renewing plan years if they are eligible
  Employees are blocked in the middle of plan shopping if they are not eligible
  and allowing them to complete plan shopping if they are eligible

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active renewal employer with health benefits
    Given Qualifying life events are present
    And there is an employer ABC Widgets

  Scenario: Employee can buy coverage under previous expired plan year using QLE if he is eligible
    Given renewal employer ABC Widgets has expired and renewal active benefit applications
    And there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    When Employee click the "Had a baby" in qle carousel
    And Employee select a qle date based on expired plan year
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the expired plan year
    When Employee selects a plan on the plan shopping page
    Then Patrick Doe should see coverage summary page with qle effective date
    Then Patrick Doe should see the receipt page with qle effective date as effective date
    Then Patrick Doe should see "my account" page with enrollment

  Scenario: Employee can buy coverage from active plan year through qle with active plan year's plans in renewal period
    Given renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    When Employee click the "Had a baby" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the active plan year
    When Employee selects a plan on the plan shopping page
    Then Patrick Doe should see coverage summary page with qle effective date
    Then Patrick Doe should see the receipt page with qle effective date as effective date
    Then Patrick Doe should see "my account" page with enrollment

  @bug @wip
   Scenario: Employee should be blocked from plan shopping if their eligibility date greater than their effective date
    Given renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    When Employee click the "Had a baby" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
  # TODO # Fix scenario after bug fixed
    Then Employee should see "You are attempting to purchase coverage through qle proir to your eligibility date" error message

  Scenario: Employee Receives Secure Enrollment Message after purchasing plan
    Given renewal employer ABC Widgets has expired and renewal active benefit applications
    And there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    When Employee click the "Had a baby" in qle carousel
    And Employee select a qle date based on expired plan year
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And Patrick Doe should see the plans from the expired plan year
    When Employee selects a plan on the plan shopping page
    Then Patrick Doe should see coverage summary page with qle effective date
    Then Patrick Doe should see the receipt page with qle effective date as effective date
    Then Patrick Doe should see "my account" page with enrollment
    When the user visits messages page
    And Patrick Doe clicks the most recent message in the inbox
    Then Patrick Doe should see the appropriate SHOP template text

  Scenario: Employee should see the correct EE contribution on their current plan when doing plan shop
    Given renewal employer ABC Widgets has expired and renewal active benefit applications
    And there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And Patrick Doe should have a ER sponsored enrollment
    When Employee click the "Married" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    Then Employee should see their current plan
    Then Employee should see the correct employee contribution on plan tile