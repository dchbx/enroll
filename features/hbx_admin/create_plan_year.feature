Feature: Create Benefit Application by admin UI

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role

  Scenario Outline: Existing Draft Application
    Given initial employer ABC Widgets has <aasm_state> benefit application with terminated on <event>
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    And the user has clicked the Create Plan Year button
    And the user has a valid input for all required fields
    When the admin clicks SUBMIT
    Then the user will see a <message> message
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    And the draft application will <action>
    And the existing applications for ABC Widgets will be <title>

    # draft_py_date_gt_term_on: 'draft benefit application' effective on is greater than 'termination pending benefit application' terminated on
    # draft_py_date_lt_term_on: 'draft benefit application' effective on is less than 'termination pending benefit application' terminated on
    Examples:
      | aasm_state | title    | event                 | message                                | action     |
      | draft      | Canceled | draft_py_effective_on | Successfully created a draft plan year | be created |


  Scenario Outline: Existing <title> Application for confirm  button
    Given initial employer ABC Widgets has <aasm_state> benefit application
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    And the user has clicked the Create Plan Year button
    And the user has a valid input for all required fields
    When the admin clicks SUBMIT
    Then the user will see a <message> message
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    And the existing applications for ABC Widgets will be <after_submit_title>

    Examples:
      | title                 | aasm_state            | after_submit_title                | message |
      | Publish Pending       | pending               | Publish Pending                   | Existing plan year with overlapping coverage exists |
      | Enrolling             | enrollment_open       | Enrolling                         | Existing plan year with overlapping coverage exists |
      | Enrollment Closed     | enrollment_closed     | Enrollment Closed                 | Existing plan year with overlapping coverage exists |
      | Enrolled              | binder_paid           | Enrolled                          | Existing plan year with overlapping coverage exists |
      | Enrollment Ineligible | enrollment_ineligible | Enrollment Ineligible             | Existing plan year with overlapping coverage exists |
      | Active                | active                | Active                            | Existing plan year with overlapping coverage exists |

  Scenario: Creating New Plan Year while application is in termination_pending aasm_state
    And initial employer ABC Widgets has active benefit application
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user clicks the Plan Years button
    Then the user will select benefit application to terminate
    When the user clicks Actions for current benefit application
    When the user clicks Actions for that benefit application
    Then the user will see Terminate button
    When the user enters last_day and other details for voluntary termination
    When user clicks submit button
    Then user should see termination successful message
    And user logs out
    And staff role person logged in
    And update rating area
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    And staff role person clicked on benefits tab
    Then employer should see benefit application in termination pending state
    And employer should see Add Plan Year link
    Then employer should see add plan year button
    And employer clicks Add Plan Year link
    And employer clicks OK in warning modal
    #Then employer should see continue button disabled
    And employer filled all the fields on benefit application form
    And employer clicked on continue button
    Then employer should see form for benefit package
    And employer filled all the fields on benefit package form for off-cycle application
    And employer selected by metal level plan offerings
    Then employer should see gold metal level type
    And employer clicked on gold metal level
    Then employer should see create plan year button disabled
    And employer selected 100 contribution percent for the application
    Then employer should see your estimated montly cost
    And employer should see that the create plan year is true
