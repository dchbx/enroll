Feature: This gives the user access to application level navigation for applicants

  Background: Your Preferences Page
    Given that the user is on FAA Household Info: Family Members page
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page
    Given the user clicks CONTINUE
    Then the user is on the Your Preferences page

  Scenario: Defaulted to "I AGREE"
    Given the user is on the Your Preferences page
    Then the answer to "To make it easier to determine my eligibility..." is defaulted to "I AGREE"
    When the user clicks CONTINUE
    Then the user should navigate to the Submit Your Application page

  Scenario: User selects "I DISAGREE"
    Given the user selects I DISAGREE
    Then the "How long would you like your eligibility for help paying for cost saving to be renewed?" question displays
    When the user selects 3 years for eligibility length question   
    And the user clicks CONTINUE
    Then the user should navigate to the Submit Your Application page
    And the field corresponding to renewal should be defaulted to 3 years in the data model
