Feature: Employee products sorted when employee click on Plan name, Premium Amount, Deductible and Carrier.
    Given Employer exists with enrolling plan year
    Given New Employee is on Census Employee Roster
    Given New Employee claimed his employee role
    Then Employee goes for plan shopping
    And Employee should be able to see available products and sorting enabled

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has enrollment_open benefit application with Metal Level plan options
    And there is a census employee record for Patrick Doe for employer Acme Inc.

  Scenario: Employee sort plans by Plan name
    Given employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal
    When Employee clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    When Employee filters plans by Carrier
    Then Employee should see plans filtered by Carrier
