Feature: Add search functionality for admin to search employer
  In order for the Hbx admin to search for employers through searchbox

  Scenario: Search for an employer
  Given a Hbx admin with read and write permissions and employers
    When Hbx AdminEnrollments logs on to the Hbx Portal
    And Hbx Admin click on Employers
    When Admin enters employers hbx id and press enter
    Then Admin should see the matched employer record form
