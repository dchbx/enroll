Feature: Outstanding Verifications screen

  Background:
    Given oustanding verfications users exists
    Given one fully uploaded person exists
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal

  Scenario: Navigate to outstanding verifications screen
    When Admin clicks Outstanding Verifications
    Then the Admin is navigated to the Outstanding Verifications screen
    Then the Admin has the ability to use the following filters for documents provided: Fully Uploaded, Partially Uploaded, None Uploaded, All
    And Admin clicks the Fully Uploaded filter and does not see results
    And Admin clicks Documents Uploaded and sorts results by documents uploaded
    And Admin clicks All and sees all of the results
    And Admin clicks Name and sorts results by name
    And Admin clicks All and sees all of the results
    Then the Admin is directed to that user's My DC Health Link page

  Scenario: Show only fully uploaded people when using Fully Uploaded Filter
    When Admin clicks Outstanding Verifications
    Then the Admin is navigated to the Outstanding Verifications screen
    And Admin clicks the Fully Uploaded filter and only sees fully uploaded results

  Scenario: User searches by verification date only shows best verification dates within specified range
    Given user with best verification due date 3 months from now is present
    And other users do not have a best verification due date
    When Admin clicks Outstanding Verifications
    Then the Admin is navigated to the Outstanding Verifications screen
    And Admin searches for user with best verification date between 8 months and 5 months ago
    Then the only user visible in the search results will be the user in that date range

