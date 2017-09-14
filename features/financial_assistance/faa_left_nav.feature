Feature: A dedicated page that gives the user access to household member creation/edit as well as Financial application forms for each household member.

Background: Left Nav
  Given that an FA application is in the draft state
  And the user is on the FAA Household Info: Family Members page
  And the left column will present the following sections Financial Assistance, Household Info & Review & Submit

Scenario: Left Nav Links
  Given the user is on the FAA Household Info: Family Members page
  When the user clicks the Financial Applications link in left nav
  Then the user will navigate to the household's Application Index page

Scenario: Left Nav Links
  Given the user is on the FAA Household Info: Family Members page
  When the user clicks the Household Info link in left nav
  Then the user will navigate to the household's info page

Scenario: Left Nav Links
  Given the user is on the FAA Household Info: Family Members page
  When the user clicks the Review & Submit link in left nav
  Then the user will NOT navigate due to the link being disabled.

Scenario: CONTINUE button navigation
  Given the user is on the FAA Household Info: Family Members page
  When the user clicks CONTINUE
  And at least one applicant is in the In Progress state
  And all member to member relationships are NOT nil
  Then the user will navigate into the first incomplete applicant's Income & Coverage page

Scenario: CONTINUE button navigation
  Given the user is on the FAA Household Info: Family Members page
  When the user completes application
  And the user clicks CONTINUE
  And all applicants are in a COMPLETED state
  Then all member to member relationships are NOT nil

Scenario: CONTINUE button navigation
  Given the user is on the FAA Household Info: Family Members page
  When the user completes application
  And all applicants are in a COMPLETED state
  And now add two more members to the family with at least one relationship as Unrelated
  And at least one member to member relationships is NIL
  And the user clicks CONTINUE
  Then the user will navigate to Household Relationships page

Scenario: CONTINUE button navigation
  Given the user is on the FAA Household Info: Family Members page
  When at least one applicant is in the In Progress state
  And now add two more members to the family with at least one relationship as Unrelated
  And at least one member to member relationships is NIL
  And the user clicks CONTINUE
  Then the user will navigate to Household Relationships page
