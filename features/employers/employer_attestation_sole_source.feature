@attestation_disabled
Feature: Employer Profile
  In order for initial employers to submit application
  Employer Staff should upload attestation document
  Background:
    Given shop health plans exist for both last and this year
    Given only sole source plans are offered
    When I visit the Employer portal
    Then Jack Doe create a new account for employer
    Then I should see a successful sign up message
    And I select the all security question and give the answer
    When I have submit the security questions
    Then I should click on employer portal
    Then Jack Doe creates a new employer profile with default_office_location
    When I go to the Profile tab
    When Employer goes to the benefits tab I should see plan year information
    And Employer should see a button to create new plan year
    And Employer should be able to enter sole source plan year, benefits, relationship benefits for employer
    And Employer should see a success message after clicking on create plan year button

  Scenario: Initial employer tries to submit application without uploading attestation
    When Employer goes to the benefits tab I should see plan year information
    When Employer clicks on publish plan year
    # TODO This doesn't work this way anymore?
    # Then Employer Staff should see dialog with Attestation warning
    # When Employer Staff clicks cancel button in Attestation warning dialog
    # Then Employer Staff should redirect to plan year edit page
