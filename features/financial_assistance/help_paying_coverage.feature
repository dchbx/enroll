Feature: Help Paying for Coverage

  Consumer will be redirected to Help Paying for Coverage page only when
  Financial Assistance feature is enabled. When FAA feature disabled,
  consumer shall not be able see or access Help Paying for Coverage page.

  Background:
    Given the user is applying for a CONSUMER role
    And the primary member has filled mandatory information required
    And the primary member authorizes system to call EXPERIAN
    And system receives a positive response from the EXPERIAN

  Scenario: FAA Feature Is Disabled - Consumer will redirect to Family members page
    Given the FAA feature configuration is disabled
    And the user answers all the VERIFY IDENTITY  questions
    When the user clicks on submit button
    And the Experian returns a VERIFIED response
    Then the consumer will navigate to the Family Members page

  Scenario: FAA Feature Is Disabled - Consumer can not have access to the Help Paying for Coverage Page
    Given the FAA feature configuration is disabled
    When the consumer manually enters the "Help Paying for Coverage" url in the browser search bar
    Then the consumer will not have access to the Help Paying for Coverage page

  Scenario: FAA Feature Is Enabled - Consumer will redirect to Help Paying for Coverage page
    Given the FAA feature configuration is enabled
    And the user answers all the VERIFY IDENTITY  questions
    When the user clicks on submit button
    And the Experian returns a VERIFIED response
    Then the consumer will navigate to the Help Paying for Coverage page
  
  Scenario: FAA Feature Is Enabled - Consumer can access the Help Paying for Coverage Page
    Given the FAA feature configuration is enabled
    When the consumer manually enters the "Help Paying for Coverage" url in the browser search bar
    Then the consumer will navigate to the Help Paying for Coverage page
