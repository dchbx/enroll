Feature: Outstanding Verifications screen

  Background:
    Given oustanding verfications users exists
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal

  Scenario: Navigate to outstanding verifications screen
    When Admin clicks Outstanding Verifications
    Then the Admin is navigated to the Outstanding Verifications screen
    Then the Admin has the ability to use the following filters for documents provided: Fully Uploaded, Partially Uploaded, None Uploaded, All
    Then the Admin is directed to that user's My DC Health Link page
