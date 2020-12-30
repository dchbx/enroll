Feature: Broker creates a quote for a prospect employer
    In order for Brokers to create a quote to Employers
    The Broker should be able to add Employer and Employees
    And Generate a quote

  Background: Set up employer, broker and their relationship
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And the Plans exist
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
    And this employer renewal application is under open enrollment
    And there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    And employer ABC Widgets hired broker Max Planck from District Brokers Inc

  Scenario Outline: Broker should be not able to create a quote with flexible rules for a renewing employer
    Given Max Planck logs on to the Broker Agency Portal
    When the broker clicks on the Employers tab
    When the broker clicks Actions for that Employer
    Then the broker sees Create Quote button
    Then the broker clicks on Create Quote button
    And the broker sees quote for ABC Widgets employer
    And the broker clicks on Select Health Benefits button
    Then the broker selects plan offerings by metal level and enters <contribution_pct> for employee and deps
    Then broker sees that publish button is <publish_button>

    Examples:
      | contribution_pct | publish_button |
      | 0                | disabled       |
      | 50               | enabled        |
      | 100              | enabled        |
