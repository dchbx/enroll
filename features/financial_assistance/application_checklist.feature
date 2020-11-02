Feature: A dedicated page that gives the user prior notice that that application will require a large amount of information for every member of the household.

  Background:
    Given the FAA feature configuration is enabled
    Given the user is applying for a CONSUMER role
    And the primary member has filled mandatory information required
    And the primary member authorizes system to call EXPERIAN
    And system receives a positive response from the EXPERIAN
    And the user answers all the VERIFY IDENTITY  questions
    When the user clicks on submit button
    And the Experian returns a VERIFIED response
    Then the user will navigate to the Help Paying for Coverage page
    And saves a YES answer to the question: Do you want to apply for Medicaid…

  Scenario: User clicks previous or the back browser button.
    Given that the user is on the Application Checklist page
    When the user clicks the PREVIOUS link
    Then the user will navigate to the Help Paying for Coverage page

  Scenario: User clicks Save & Exit
    Given that the user is on the Application Checklist page
    When the user clicks the SAVE & EXIT link
    Then the next time the user logs in the user will see Application checklist page
