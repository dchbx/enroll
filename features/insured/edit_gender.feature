Feature: Edit Gender on Manage Family Page
  As both a user and/or an admin, I should be able to edit the gender from the family account landing page.
  Scenario: Existing user edits gender from manage family page. 
    Given I am a consumer
    And my gender is set to male
    When I visit the Families Home Page
    And then I click on the Manage Family link.
    And then I click on the Personal tab
    Then male should be selected
    And I click female
    And I click Save
    Then Person was successfully updated appears. 