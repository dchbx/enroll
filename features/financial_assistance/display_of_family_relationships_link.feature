Feature: Conditional Display of Family Relationships link in the left nav of the FAA Household Info page.

  Background: Household Info page
    Given that an FA application is in the draft state
    And the user is on the FAA Household Info: Family Members page

  Scenario: Relationships link does not display when there is only one household member
    Given that the user is on the FAA Household Info: Family Members page
    And the primary member exists
    Then Family Relationships left section will NOT display

  Scenario: Relationships link displays when there is more than one household member
    Given that the user is on the FAA Household Info: Family Members page
    And the primary member exists
    And at least one other household members exist
    Then Family Relationships left section WILL display

  Scenario: Relationships link is disabled when at least on applicant is in progress
    Given that the user is on the FAA Household Info: Family Members page
    And at least one other household members exist
    And at least one applicant is in the Info Needed state
    And the Family Relationships link displays in the left column of the page
    Then the Family Relationships link is disabled 


  Scenario: Relationships link is enabled when all applicants are complete.
    Given that the user is on the FAA Household Info: Family Members page
    And at least one other household members exist
    And all applicants are in Info Completed state
    And the Family Relationships link displays in the left column of the page
    Then the Family Relationships link is enabled 


Scenario: Navigation to Family Relationships page via Relationships link
    Given that the user is on the FAA Household Info: Family Members page
    And at least one other household members exist
    And all applicants are in Info Completed state
    And the Family Relationships link displays in the left column of the page
    And the Family Relationships link is enabled 
    When the user clicks the Family Relationships link
    Then the user will navigate to the Family relationships page



