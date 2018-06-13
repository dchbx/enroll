@individual_enabled
Feature: Hbx staff create announcements for consumer role

  Scenario: Hbx staff create announcements for consumer role
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx admin should see the link of announcements and click
    Then Hbx admin should see the page of announcements
    When Hbx admin enter announcement info
    Then Hbx admin should see the current announcement
    When Hbx admin enter announcement info with future date
    Then Hbx admin should not see the future announcement
    When Hbx admin click the link of all
    Then Hbx admin should see the future announcement
    When Hbx admin enter announcement info with invalid params
    Then Hbx admin should see the alert msg
    Then Hbx admin logs out

  Scenario: Consumer see announcement for consumer role
    Given Announcement prepared for Consumer role
    Given Consumer role exists
    When Consumer login
    Then Consumer should see announcement
    When Consumer click the link of documents
    Then Consumer should not see announcement
    When Consumer click the link of homepage
    Then Consumer should see announcement

  Scenario: Employer do not see announcement for consumer role
    Given Announcement prepared for Consumer role
    Given Employer role exists
    When Employer login
    Then Employer should not see announcement
