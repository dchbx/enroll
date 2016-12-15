Feature: Employer should claim a quote from his broker

  Scenario: An Employer should be able to claim a quote from his broker
    Given an employer exists
    And the employer has employees
    And the employer is logged in
    When the employer goes to benefits tab
    And the employer clicks on claim quote
    Then the employer enters claim code for his quote
    When the employer clicks claim code
    Then the employer sees a successful message
    And the employer logs out
