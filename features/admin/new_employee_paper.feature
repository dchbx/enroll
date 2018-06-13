Feature: Phone and Paper Enrollment options exist
  In order to support paper enrollments
  Link is provided that will track paper enrollment

  Background:
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab


  Scenario: Phone and Phone Enrollment
    Then I see the Paper link
    And Hbx Admin clicks on the link of New Employee Paper Application
    Then HBX admin start new employee enrollment