Feature: Hbx Admin Bulk Notice

Background: Admin has ability to create a new Bulk Notice
  Given an HBX admin exists
  And the HBX admin is logged in
  And there is an employer ACME

Scenario: Admin will create a new bulk notice
  Given Admin is on the new Bulk Notice view
  When Admin selects Employer
  And Admin fills form with ACME FEIN
  Then Admin should see ACME badge
  When Admin fills in the rest of the form
  And Admin clicks on Preview button
  Then Admin should see the Preview Screen
