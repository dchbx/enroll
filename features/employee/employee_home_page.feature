Feature: Employee only user should be able to enroll in IVL market

  Scenario: User with only employee role
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And this employer offering 0.75 contribution to Employee
    And this employer ABC Widgets has first_of_month rule
    Given there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And Employee should see a button to enroll in ivl market
    And Employee clicks on Enroll
    Then Employee redirects to ivl flow
    And Employee logs out

  Scenario: User exists with dual roles
    Given a person exists with dual roles
    Then Dual Role Person sign in to portal
    Then Dual Role Person should not see any button to enroll in ivl market
    And Dual Role Person logs out
