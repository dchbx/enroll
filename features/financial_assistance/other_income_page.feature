Feature: Other income page

  Background: Other income page
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the user will navigate to the FAA Household Info page
    When they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And the user clicks Other Income section on the left navigation
    And the user will navigate to the Other Income page for the corresponding applicant

  Scenario: User answers no to having other income
    Given the user answers no to having other income
    Then the other income choices should not show

  Scenario: User answers yes to having other income
    Given the user answers yes to having other income
    Then the other income choices should show

  Scenario: Other income form shows after checking an option
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    Then the other income form should show

  Scenario: User enters other income information
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    And the user fills out the required other income information
    Then the save button should be enabled
    And the user saves the other income information
    Then the other income information should be saved on the page

  Scenario: Cancel button functionality
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    When the user cancels the form
    Then the other income checkbox should be unchecked
    And the other income form should not show

  Scenario: Confirmation pop-up functionality
    When the user clicks the BACK TO ALL HOUSEHOLD MEMBERS link
    Then a modal should show asking the user are you sure you want to leave this page
