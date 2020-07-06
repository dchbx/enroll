Feature: Newly designated employees can purchase coverage only through renewing plan year
  In order to make employees purchase coverage only using renewal plan year
  Employee should be blocked from buying coverage under previous year plan year

Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer Acme Inc.
    And renewal employer Acme Inc. has active and renewal enrollment_open benefit applications
    And Acme Inc. employer has a staff role 
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And census employee Patrick Doe is a newly_designated_eligible employee
    And this employer Acme Inc. has first_of_month rule

  Scenario: Newly designated should not get effective date before renewing plan year start date
    Given Employee has not signed up as an HBX user
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    When Employee clicks "Shop for Plans" on my account page
    And employee Patrick Doe has earliest eligible date under current active plan year
    Then Employee should see the group selection page
    And employee Patrick Doe should see renewing benefit application start date as effective date
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    When Patrick Doe selects a plan on the plan shopping page
    Then Patrick Doe should see coverage summary page with renewing benefit application start date as effective date
    Then Patrick Doe should see the receipt page with renewing plan year start date as effective date