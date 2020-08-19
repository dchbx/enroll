Feature: The different eligibility response pages received after submitting an application

  Background:
    Given that the user is on FAA Household Info: Family Members page     
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page
    When the user clicks CONTINUE
    Then the user is on the Your Preferences page
    When the user clicks CONTINUE
    Then the user is on the Submit Your Application page
    When all required questions are answered
    And the user has signed their name

  Scenario: Application is not correct (submission error)
    Given the user clicks SUBMIT
    Then the user is on the Error Submitting Application page 
  
  Scenario: Eligibility response error
    Given the application is correct
    And the user clicks SUBMIT
    And the user is on the Waiting for Results page
    Then the user is on the Eligibility Response Error page

  Scenario: User does qualify for assistance
    Given the application is correct
    And the user clicks SUBMIT
    And the user is on the Waiting for Results page
    And the user qualifies for "assistance"
    Then the user is on the Eligibility Results page
    And the user's "assistance" results show

  Scenario: User qualifies for medicaid
    Given the application is correct
    And the user clicks SUBMIT
    And the user is on the Waiting for Results page
    And the user qualifies for "medicaid"
    Then the user is on the Eligibility Results page
    And the user's "medicaid" results show

  Scenario: User does not qualify for assistance
    Given the application is correct
    And the user clicks SUBMIT
    And the user is on the Waiting for Results page
    And the user qualifies for "no assistance"
    Then the user is on the Eligibility Results page
    And the user's "no assistance" results show

  Scenario: View my Applications link functionalitiy 
    Given the application is correct
    And the user clicks SUBMIT
    And the user qualifies for "no assistance"
    And the user is on the Eligibility Results page
    When the user clicks View My Applications
    Then the user will be on the Cost Savings Applications page