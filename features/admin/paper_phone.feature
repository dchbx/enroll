Feature: Phone and Paper Enrollment options exist
  In order to support paper and phone enrollments
  Links are provided that will track phone and paper enrollments

  Background:
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And the Hbx Admin clicks on the Action button

  Scenario: Phone and Phone Enrollment
    Then I see the Paper link
    Then I see the Phone link


