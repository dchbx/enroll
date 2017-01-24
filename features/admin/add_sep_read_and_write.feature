Feature: Add Sep with read and write permissions
  In order to limit who can give an enrollment a Sep,
  only hbx admins with read and write permissions can have the
  add SEP menu item enabled from the family index page.

  Background:
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And the Hbx Admin clicks on the Action button

  Scenario: Click on Add Sep
    Then the Add SEP option should be enabled

  Scenario: Click on Cancel Enrollment
    Then the Cancel Enrollment option should be enabled

  Scenario: Click on Terminate Enrollment
    Then the Terminate Enrollment option should be enabled

  #TODO: Need to a similar test for the Edit APTC/CSR link when APTC functionality is implemented
