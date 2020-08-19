Feature: This gives the user access to application level navigation for applicants

  Background: Household Info page
    Given that the user is on FAA Household Info: Family Members page
    When the user clicks ADD/EDIT INCOME & COVERAGE INFO button for a given household member
    Then the user will navigate to the Tax Info page for the corresponding applicant.

  Scenario: Navigate from Tax Info to FAA Household Info page
    Given that the user is on the Tax Info page for a given applicant
    When the user clicks My Household section on the left navigation
    Then the user will navigate to the FAA Household Info page for the corresponding application.

  Scenario: Disable cursor when clicking Income & Coverage 
    Given that the user is on the Tax Info page for a given applicant
    When the user clicks Income & Coverage section on the left navigation
    Then the cursor will display disabled.

  Scenario: Navigate from Tax Info to Job Income Info page
    Given that the user is on the Tax Info page for a given applicant
    When the user clicks Job Income section on the left navigation
    Then the user will navigate to the Job Income page for the corresponding applicant

  Scenario:  Navigate from Tax Info to Other Income page
    Given that the user is on the Tax Info page for a given applicant
    When the user clicks Other Income section on the left navigation
    Then the user will navigate to the Other Income page for the corresponding applicant.

  Scenario: Navigate from Tax Info to Income Adustments page
    Given that the user is on the Tax Info page for a given applicant
    When the user clicks Income Adjustments section on the left navigation
    Then the user will navigate to the Income Adjustments page for the corresponding applicant

  Scenario: Navigate from Tax Info to Health Coverage page
    Given that the user is on the Tax Info page for a given applicant
    When the user clicks Health Coverage section on the left navigation
    Then the user will navigate to the Health Coverage page for the corresponding applicant

  Scenario: Navigate from Tax Info to Other Questions page
    Given that the user is on the Tax Info page for a given applicant
    When the user clicks Other Questions section on the left navigation
    Then the user will navigate to the Other Questions page for the corresponding applicant
