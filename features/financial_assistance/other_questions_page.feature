Feature: Start a new Financial Assistance Application and answers questions on Other Questions page

  Background: User logs in and visits applicant's other questions page
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the user SSN is nil
    And the user has an eligible immigration status
    And the user has an age between 18 and 19 years old
    And the user will navigate to the FAA Household Info page
    When they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And the user clicks Other Questions section on the left navigation
    And the user will navigate to the Other Questions page for the corresponding applicant

  Scenario: SSN question
    Given the user SSN is nil
    And the user will navigate to the Other Questions page for the corresponding applicant
    And the have you applied for an SSN question should display
    And the user answers no to the have you applied for an SSN question
    Then the reason why question is displayed

  Scenario: Pregnancy question - yes
    Given the user answers yes to being pregnant
    Then the due date question should display
    And how many children question should display

  Scenario: Pregnancy question - no
    Given the user answers no to being pregnant
    And was this person pregnant in the last 60 days question should display
    When they answer yes to was this person pregnant in the last 60 days question
    Then pregnancy end date question should display

  Scenario: If they were pregnant, were they on medicaid?
    Given the user answers no to being pregnant
    And they answer yes to was this person pregnant in the last 60 days question
    Then the has this person ever been in foster care question should display

  Scenario: Foster care questions
    Given the user has an age between 18 and 26 years old
    Then the has this person ever been in foster care question should display

  Scenario: Foster care - answered yes
    Given the user has an age between 18 and 26 years old
    And the user answered yes to the has this person ever been in foster care question
    Then the where was this person in foster care question should display
    And the how old was this person when they left foster care question should display
    And the was this person enrolled in medicare when they left foster care should display

  Scenario: Student question
    Given the user has an age between 18 and 19 years old
    Then the is this person a student question should display

  Scenario: Student question - answered yes
    Given the user has an age between 18 and 19 years old
    And the user answers yes to being a student
    Then the type of student question should display
    And student status end date question should display
    And type of school question should display

  Scenario: Immigration related question
    Given the user has an eligible immigration status
    And the user answers yes to having an eligible immigration status
    Then the did you move to the US question should display
    And the military veteran question should display

  Scenario: Answered yes to military question
    Given the user answers yes to having an eligible immigration status
    And user answers yes to the military veteran question
    Then the are you a spouse of such a veteran question should display
