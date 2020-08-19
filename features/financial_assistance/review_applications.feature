Feature: My Financial Assistance Applications page that visit the Review Application page
  Scenario: Review Application link will be disabled in draft state
    Given that a family has a Financial Assistance application in the “draft” state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the “draft” application
    Then the "Review Application" link will be disabled

  Scenario: Review Application link will be disabled in submitted state
    Given that a family has a Financial Assistance application in the “submitted” state
    And the user navigates to the “Help Paying For Coverage” portal
    When clicks the “Action” dropdown corresponding to the “submitted” application
    Then the “Review Application” link will be actionable

  Scenario: Review Application link will be disabled in determination_response_error state
    Given that a family has a Financial Assistance application in the “determination_response_error” state
    And the user navigates to the “Help Paying For Coverage” portal
    When the user clicks the “Action” dropdown corresponding to the “determination_response_error” application
    Then the “Review Application” link will be actionable

  Scenario: Review Application link will be disabled in determined state
    Given that a family has a Financial Assistance application in the “determined” state
    And the user navigates to the “Help Paying For Coverage” portal
    When clicks the “Action” dropdown corresponding to the “determined” application
    Then the “Review Application” link will be actionable

  Scenario: Review Application link will be disabled in submitted state
    Given that a family has a Financial Assistance application in the “submitted” state
    And the user navigates to the “Help Paying For Coverage” portal
    When clicks the “Action” dropdown corresponding to the “submitted” application
    And the “Review Application” link will be actionable
    And clicks the “Review Application” link
    Then the user will navigate to the Review Application page
