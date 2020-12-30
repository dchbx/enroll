@wip
Feature: Admin Assigns a General Agency to an Employer

  Background:
    Given a general agency, approved, confirmed, exists
    And a broker exists
    And a Hbx admin with read and write permissions exists

  Scenario: Then the Admin should see the 'Assign' link under the broker profile
    And Hbx Admin logs on to the Hbx Portal
    And Hbx Admin clicks on the Broker Agencies tab
    And Hbx Admin clicks on the broker
    Then he should be able to see the Assign link under his profile
