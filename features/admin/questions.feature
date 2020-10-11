@ma_only
Feature: Add, Edit and Delete security questions

  Background: Setup Site
    Given a CCA site exists with a benefit market

  Scenario: Hbx Admin can add new security question
    Given Admin is a person
    Given Admin has already provided security question responses
    Given Admin has HBXAdmin privileges
    And the user is on the Admin Tab of the Admin Dashboard
    And the user click on config drop down in the Admin Tab
    And user click on Security Question link
    And there is 3 questions available in the list
    And user will clicks on New Question link
    Then Hbx Admin should see New Question form
    And user fill out New Question form detail
    When Hbx Admin submit the question form
    Then there is 4 questions available in the list

  Scenario: Hbx Admin can edit security question
    Given Admin is a person
    Given Admin has already provided security question responses
    Given Admin has HBXAdmin privileges
    And the user is on the Admin Tab of the Admin Dashboard
    And the user click on config drop down in the Admin Tab
    And user click on Security Question link
    And there is 3 questions available in the list
    When Hbx Admin click on Edit Question link
    Then Hbx Admin should see Edit Question form
    And Hbx Admin update the question title
    When Hbx Admin submit the question form
    Then there is 0 questions available in the list
    And the question title updated successfully

  Scenario: Hbx Admin should see already in use text when existing security question already present
    Given Admin is a person
    Given Admin has already provided security question responses
    Given Admin has HBXAdmin privileges
    And the user is on the Admin Tab of the Admin Dashboard
    And the user click on config drop down in the Admin Tab
    And user click on Security Question link
    And there is 3 questions available in the list
    When Hbx Admin click on Delete Question link
    Then Hbx Admin confirm popup
    Then user should see already in use text