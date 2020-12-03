Feature: Employee passive renewal should be canceled when Employee selected coverage

  After a passive renewal if employee makes a plan selection, passive renewal should be canceled

  Background: Setup site, employer, and benefit application
    Given HbxProfile exists
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And this employer ABC Widgets has first_of_month_after_30_days rule
    And this employer renewal application is under open enrollment

  Scenario: Renewing employee makes plan selection

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And Patrick Doe has active coverage and passive renewal
    Then Patrick Doe should see active and renewing enrollments
    When Patrick Doe clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    When Patrick Doe selects a plan on the plan shopping page
    Then Patrick Doe should see coverage summary page with renewing benefit application start date as effective date
    Then Patrick Doe should see the receipt page with renewing plan year start date as effective date
    Then Patrick Doe should see "my account" page with new enrollment and passive renewal should be canceled
