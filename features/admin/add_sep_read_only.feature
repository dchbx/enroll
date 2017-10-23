Feature: Add Sep with read only permissions
  In order to limit who can give an enrollment a Sep,
  only hbx admins with read and write permissions can have the
  add SEP menu item enabled from the family index page.

  Background:
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    When Hbx Admin clicks on Families link
    And the Hbx Admin clicks on the Action button

  Scenario: Click on Add Sep
    Then the Add SEP option should be disabled

  Scenario: Click on Cancel Enrollment
    Then the Cancel Enrollment option should be disabled

  Scenario: Click on Terminate Enrollment
    Then the Terminate Enrollment option should be disabled

  #TODO: Need to a similar test for the Edit APTC/CSR link when APTC functionality is implemented
