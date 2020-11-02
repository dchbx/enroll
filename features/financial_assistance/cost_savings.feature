Feature: Cost Savings

  Consumer will be able to access Cost Savings page only when
  Financial Assistance feature is enabled. When FAA feature disabled,
  consumer shall not be able see or access Cost Savings page.


  Background:
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp

  Scenario: FAA Feature Is Disabled - Consumer can not see the Cost Savings Link
    Given the FAA feature configuration is disabled
    When consumer visits home page
    Then the consumer will not see the Cost Savings link

  Scenario: FAA Feature Is Disabled - Consumer can not have access to the Cost Savings Page
    Given the FAA feature configuration is disabled
    When the consumer manually enters the "Cost Savings" url in the browser search bar
    Then the consumer will not have access to the Cost Savings page

  Scenario: FAA Feature Is Enabled - Consumer can see the Cost Savings Link
    Given the FAA feature configuration is enabled
    When consumer visits home page
    Then the Cost Savings link is visible

  Scenario: FAA Feature Is Enabled - Consumer can navigate to the Cost Savings Page
    Given the FAA feature configuration is enabled
    Given consumer visits home page
    And the Cost Savings link is visible
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page

  Scenario: FAA Feature Is Enabled - Consumer can access the Cost Savings Page
    Given the FAA feature configuration is enabled
    When the consumer manually enters the "Cost Savings" url in the browser search bar
    Then the consumer will navigate to the Cost Savings page
