Feature: Add, Edit and Delete security questions

  Scenario: Hbx Admin can add new security question
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And I select the all security question and give the answer
    When I have submit the security questions
    And Hbx Admin clicks on the Admin dropdown
    And Hbx Admin clicks on the Config option
    And Hbx Admin should see Security Question link
    And Hbx Admin clicks on Security Question link
    And there is 0 questions available in the list
    When Hbx Admin clicks on New Question link
    Then Hbx Admin should see New Question form
    And Hbx Admin fill out New Question form detail
    When Hbx Admin submit the question form
    Then there is 1 questions available in the list

  Scenario: Hbx Admin can edit and update an existing security question
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And I select the all security question and give the answer
    When I have submit the security questions
    And Hbx Admin clicks on the Admin dropdown
    And Hbx Admin clicks on the Config option
    And there is 1 preloaded security questions
    And Hbx Admin should see Security Question link
    And Hbx Admin clicks on Security Question link
    And there is 1 questions available in the list
    When Hbx Admin clicks on Edit Question link
    Then Hbx Admin should see Edit Question form
    And Hbx Admin update the question title
    When Hbx Admin submit the question form
    Then there is 1 questions available in the list
    And the question title updated successfully

  Scenario: Hbx Admin can delete an existing security question
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And I select the all security question and give the answer
    When I have submit the security questions
    And Hbx Admin clicks on the Admin dropdown
    And Hbx Admin clicks on the Config option
    And there is 1 preloaded security questions
    And Hbx Admin should see Security Question link
    And Hbx Admin clicks on Security Question link
    And there is 1 questions available in the list
    When Hbx Admin clicks on Delete Question link
    And I confirm the delete question popup
    Then there is 0 questions available in the list

  Scenario: User should select security questions after signup/login if not selected previously
    Given There are preloaded security question on the system
    When I visit the Employer portal
    Then Jack Doe create a new account for employer
    And I should see a successful sign up message
    And I can see the security modal dialog
    And I select the all security question and give the answer
    When I have submit the security questions
    Then I have landed on employer profile page
    And I click on log out link
    And I visit the Employer portal
    When Jack Doe logs on to the Employer portal
    Then I cannot see the security modal dialog
