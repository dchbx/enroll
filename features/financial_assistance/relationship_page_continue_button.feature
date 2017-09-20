Feature: Relationship page continue button navigation

Background: Family Realtionship page
Given that the user is on FAA Household Info: Family Members page
When all applicants are in Info Completed state
And user clicks CONTINUE
Then the user will navigate to Family Relationships page

Scenario: Given that the user is on the FAA Family Relationships page
When there is no missing relatioships
Then the CONTINUE button is enabled
When user clicks CONTINUE
Then the user will navigate to the Review & Submit page