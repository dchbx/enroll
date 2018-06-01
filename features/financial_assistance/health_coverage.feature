Feature: Start a new Financial Assistance Application and answers questions on health coverage page

  Background: User logs in and visits applicant's health coverage page
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the user will navigate to the FAA Household Info page
    When they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page (health coverage)
    And they visit the Health Coverage page via the left nav (also confirm they are on the Health Coverage page)

  Scenario: User answers no to currently having health coverage
    Given the user answers no to currently having health coverage
    Then the health coverage choices should not show

  Scenario: User answers no to currently having access to other health coverage
    Given the user answers no to currently having access to other health coverage
    Then the other health coverage choices should not show

  Scenario: User answers yes to currently having health coverage
    Given the user answers yes to currently having health coverage
    Then the health coverage choices should show

  Scenario: User answers yes to currently having access to other health coverage
    Given the user answers yes to currently having access to other health coverage
    Then the other health coverage choices should show

  Scenario: Health coverage form shows after checking an option (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a health coverage checkbox
    Then the health coverage form should show

  Scenario: Health coverage form shows after checking an option (currently have access to coverage)
    Given the user answers yes to currently having access to other health coverage
    And the user checks a health coverage checkbox
    Then the other health coverage form should show

  Scenario: User enters health coverage information (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a health coverage checkbox
    And the user fills out the required health coverage information
    Then the save button should be enabled
    And the user saves the health coverage information
    Then the health coverage should be saved on the page

  Scenario: User enters other health coverage information (currently have access to coverage)
    Given the user answers yes to currently having access to other health coverage
    And the user checks a health coverage checkbox
    And the user fills out the required health coverage information
    Then the save button should be enabled
    And the user saves the health coverage information
    Then the health coverage should be saved on the page

  Scenario: Cancel button functionality (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a health coverage checkbox
    When the user cancels the form
    Then the health coverage checkbox should be unchecked
    And the health coverage form should not show

  Scenario: Cancel button functionality (currently have coverage)
    Given the user answers yes to currently having access to other health coverage
    And the user checks a health coverage checkbox
    When the user cancels the form
    Then the health coverage checkbox should be unchecked
    And the health coverage form should not show