Feature: A dedicated page that gives the user access to household member creation/edit as well as Financial application forms for each household member.

  Background: Household Info page
    Given that the user is on FAA Household Info: Family Members page

  Scenario: CONTINUE button navigation
    When at least one applicant is in the Info Needed state
    Then the CONTINUE button will be disabled

  Scenario: primary member with NO other household members
    And the primary member exists
    And NO other household members exist
    Then Family Relationships left section will NOT display

  Scenario: primary member with other household members
    And the primary member exists
    And at least one other household members exist
    Then Family Relationships left section WILL display

  Scenario: CONTINUE button navigation
    When all applicants are in Info Completed state
    Then the CONTINUE button will be ENABLED

  Scenario: CONTINUE button navigation
    And at least one other household members exist
    When all applicants are in Info Completed state
    And user clicks CONTINUE
    Then the user will navigate to Family Relationships page

