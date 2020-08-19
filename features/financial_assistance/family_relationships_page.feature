Feature: Functionality for the Family Relationships page

  Background: Family Relationships page
    Given a consumer exists
    And is logged in
    And a benchmark plan exists
    And the user will navigate to the FAA Household Info page
    And at least two other household members exist
    When all applicants are in Info Completed state
    And user clicks CONTINUE
    Then the user will navigate to Family Relationships page

  Scenario: Navigation to Review Your Application page
    Given that the user is on the FAA Family Relationships page
    And there is a nil value for at least one relationship
    When the user populates the drop down with a value
    And the relationship is saved
    And all the relationships have been entered
    When the user clicks CONTINUE
    Then the user will navigate to the Review & Submit page
    
  Scenario: Continue button enabled when all relationships are entered
    Given that the user is on the FAA Family Relationships page
    And there is a nil value for at least one relationship
    When the user populates the drop down with a value
    And the relationship is saved
    And all the relationships have been entered
    Then the CONTINUE button will be ENABLED

  Scenario: Correct left nav elements 
    Given that the user is on the FAA Family Relationships page
    Then View My Applications left section WILL display
    Then Family Relationships left section WILL display
    And Review & Submit left section WILL display

  Scenario:  Missing value is highlighted
    Given that the user is on the FAA Family Relationships page
    And there is a nil value for at least one relationship
    Then the CONTINUE button will be disabled
    And the family member row will be highlighted

  Scenario: Family relationship value is stored
    Given that the user is on the FAA Family Relationships page
    And there is a nil value for at least one relationship
    When the user populates the drop down with a value
    Then the relationship is saved

   
     