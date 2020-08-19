Feature: Conditional Display of Family Relationships link in the left nav of the FAA Household Info page.

  Background: Household Info page
    Given a consumer exists
    And is logged in
    And a benchmark plan exists
    And the user will navigate to the FAA Household Info page

  Scenario: Relationships link does not display when there is only one household member
    Given the primary member exists
    Then Family Relationships left section will NOT display

  Scenario: Relationships link displays when there is more than one household member
    Given the primary member exists
    And at least one other household members exist
    Then Family Relationships left section WILL display

  Scenario: Relationships link is disabled when at least on applicant is in progress
    Given at least one other household members exist
    And at least one applicant is in the Info Needed state
    And the Family Relationships link displays in the left column of the page
    Then the Family Relationships link is disabled 

  Scenario: Relationships link is enabled when all applicants are complete.
    Given at least one other household members exist
    And all applicants are in Info Completed state
    And the Family Relationships link displays in the left column of the page
    Then the Family Relationships link is enabled 

  Scenario: Navigation to Family Relationships page via Relationships link
    Given at least one other household members exist
    And all applicants are in Info Completed state
    And the Family Relationships link displays in the left column of the page
    And the Family Relationships link is enabled 
    When the user clicks the Family Relationships link
    Then the user will navigate to the Family relationships page

  Scenario: Family relationships link displays on Review Your Application page
    Given at least one other household members exist
    And all applicants are in Info Completed state
    And the Family Relationships link displays in the left column of the page
    And the Family Relationships link is enabled 
    When the user clicks the Family Relationships link
    Then the user will navigate to the Family relationships page
    When the user clicks CONTINUE
    Then the user is on the Review Your Application page
    And Family Relationships left section WILL display

  Scenario: Family relationships link does not display on Review your Application page
    Given the primary member exists
    Then Family Relationships left section will NOT display
    When all applicants are in Info Completed state
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page
    And Family Relationships left section will NOT display


