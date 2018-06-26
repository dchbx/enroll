@individual_enabled
Feature: Employee only user should be able to enroll in IVL market

  Scenario: User with only employee role
    Given a matched Employee exists with only employee role
    Then Employee sign in to portal
    And Employee should see a button to enroll in ivl market
    And Employee clicks on Enroll
    Then Employee redirects to ivl flow
    And Employee logs out

  Scenario: User exists with dual roles
    Given a person exists with dual roles
    Then Dual Role Person sign in to portal
    Then Dual Role Person should not see any button to enroll in ivl market
    And Dual Role Person logs out
