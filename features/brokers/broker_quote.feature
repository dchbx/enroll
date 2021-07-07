Feature: Broker quote creation 
    
  Background: Broker Quoting Tool
    Given the shop market configuration is enabled
    And a CCA site exists with a benefit market
    And the Plans exist
    And the broker Max Planck is primary broker for District Brokers Inc

  Scenario: Broker should be able to create an Employer
    Given Max Planck logs on to the Broker Agency Portal
    When Primary Broker clicks on the Employers tab
    And Primary Broker clicks on the Add Prospect Employer button
    And Primary Broker creates new Prospect Employer with default_office_location
    Then Primary Broker should see successful message
    
  Scenario Outline: Roster does not populate even if employer has prior quotes with rosters completed
    Given Max Planck logs on to the Broker Agency Portal
    And prospect employer exist
    When Primary broker clicks Actions dropdown and clicks Create Quote
    And Primary Broker enters quote name
    And Primary broker clicks on Select Health Benefits button
    And Primary broker selects plan offerings by metal level and enters <contribution_pct> for employee and deps
    And Primary broker publishes the quote
    Then Primary Broker should see the quote roster is empty
    
    Examples:
      | contribution_pct |
      | 100              |

  Scenario Outline: Broker should be able to create a quote for prospect employer with flexible rules
    Given Max Planck logs on to the Broker Agency Portal
    And prospect employer exist
    When Primary broker clicks Actions dropdown and clicks Create Quote
    And Primary Broker enters quote name
    And Primary broker clicks on Select Health Benefits button
    And Primary broker selects plan offerings by metal level and enters <contribution_pct> for employee and deps
    And Primary broker publishes the quote
    Then Primary Broker should see successful message of published quote
  
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
    And Primary broker clicks Actions dropdown and clicks Create Quote
    And Primary Broker sees quote for Netflix employer
    And Primary broker clicks on Select Health Benefits button
    And Primary broker selects plan offerings by metal level and enters <contribution_pct> for employee and deps
    And Primary broker publishes the quote
    Then Primary Broker should see successful message of published quote
    
    Examples:
      | contribution_pct |
      | 0                |
      | 50               |
      | 100              |
