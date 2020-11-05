Feature: Broker creates a quote for a prospect employer
    In order for Brokers to create a quote to Employers
    The Broker should be able to add Employer and Employees
    And Generate a quote

  Background: Broker Quoting Tool
    Given a CCA site exists with a benefit market
    And the Plans exist
    And there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc

  Scenario: Broker should be able to create an Employer
    Given Max Planck logs on to the Broker Agency Portal
    When Primary Broker clicks on the Employers tab
    And Primary Broker clicks on the Add Prospect Employer button
    And Primary Broker creates new Prospect Employer with default_office_location
    And Primary Broker should see successful message
    And the broker clicks Actions dropdown and clicks View Quotes from dropdown menu
    Then Primary Broker should be on the Roster page of a View quote
    And Primary Broker should see the quote roster is empty
    And Primary Broker logs out

  Scenario Outline: Roster does not populate even if employer has prior quotes with rosters completed
    Given Max Planck logs on to the Broker Agency Portal
    When Primary Broker clicks on the Employers tab
    And Primary Broker clicks on the Add Prospect Employer button
    And Primary Broker creates new Prospect Employer with default_office_location
    And Primary Broker should see successful message
    And the broker clicks Actions dropdown and clicks Create Quote from dropdown menu
    Then Primary Broker should be on the Roster page of a Create quote
    And Primary Broker enters quote name
    And the broker clicks on Select Health Benefits button
    Then the broker selects plan offerings by metal level and enters <contribution_pct> for employee and deps
    Then broker publishes the quote
    And Primary Broker should see successful message of published quote
    And Primary Broker should see the quote roster is empty
    And Primary Broker logs out

    Examples:
      | contribution_pct |
      | 100              |

  @flaky
  Scenario Outline: Broker should be able to create a quote for prospect employer with effective date in 2020 with flexible rules
    Given Max Planck logs on to the Broker Agency Portal
    When Primary Broker clicks on the Employers tab
    And Primary Broker clicks on the Add Prospect Employer button
    And Primary Broker creates new Prospect Employer with default_office_location
    And Primary Broker should see successful message
    And the broker clicks Actions dropdown and clicks Create Quote from dropdown menu
    Then Primary Broker should be on the Roster page of a Create quote
    And Primary Broker enters quote name
    And the broker clicks on Select Health Benefits button
    Then the broker selects plan offerings by metal level and enters <contribution_pct> for employee and deps
    And the broker should see that the save benefits button is enabled
    Then broker publishes the quote
    And Primary Broker should see successful message of published quote
    And Primary Broker logs out


    Examples:
      | contribution_pct |
      | 0                |
      | 50               |
      | 100              |

  Scenario Outline: Broker should be able to create a quote with flexible rules for an existing employer
    Given there is an employer Netflix
    And employer Netflix hired broker Max Planck from District Brokers Inc
    And Max Planck logs on to the Broker Agency Portal
    When Primary Broker clicks on the Employers tab
    When Primary Broker clicks Actions for that Employer
    Then Primary Broker sees Create Quote button
    Then Primary Broker clicks on Create Quote button
    And Primary Broker sees quote for Netflix employer
    And the broker clicks on Select Health Benefits button
    Then the broker selects plan offerings by metal level and enters <contribution_pct> for employee and deps
    And the broker should see that the save benefits button is enabled
    Then broker publishes the quote
    And Primary Broker should see successful message of published quote
    And Primary Broker logs out

    Examples:
      | contribution_pct |
      | 0                |
      | 50               |
      | 100              |
