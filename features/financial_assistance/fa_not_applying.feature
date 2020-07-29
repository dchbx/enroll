Feature: User is not applying for financial assistance
  Background:
    Given the user is applying for a CONSUMER role
    And the primary member has filled mandatory information required
    And the primary member authorizes system to call EXPERIAN
    And system receives a positive response from the EXPERIAN
    And the user answers all the VERIFY IDENTITY  questions
    When the user clicks on submit button
    And the Experian returns a VERIFIED response
    Then the user will navigate to the Help Paying for Coverage page

  Scenario: Consumer is not applying for financial assistance
    Given the user navigates to the "Household Info" page with "no" selected
    When the user clicks on add member button
    And the user fills the the add member form
    And the user clicks the PREVIOUS link1
    Then the user navigates to Help Paying for Coverage page

  Scenario: Consumer is applying for financial assistance
    Given the user navigates to the "Household Info" page with "yes" selected
    And the user is navigated to Application checklist page
    When the user clicks on CONTINUE button
    Then the user will navigate to FAA Household Info: Family Members page
