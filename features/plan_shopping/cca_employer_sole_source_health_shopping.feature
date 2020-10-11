Feature: Employee of a Sole Source Employer Shopping During Open Enrollment
  Background:
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has enrollment_open benefit application
    And Acme Inc. employer has a staff role
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And employee Patrick Doe already matched with employer Acme Inc. and logged into employee portal

  Scenario: Group Selection During Open Enrollment
    When Patrick Doe clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page
    And I should see a selectable 'health' benefit option

  Scenario: Plan Browsing During Open Enrollment
    When Patrick Doe clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    And I should see the waive coverage button