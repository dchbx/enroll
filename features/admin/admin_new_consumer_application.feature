Feature: Hbx Admin creates a New Consumer Application for ivl users

  Background: Hbx Admin navigates into the new consumer application with paper application option and goes forward till DOCUMENT UPLOAD page
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And admin has navigated into the NEW CONSUMER APPLICATION
    And the Admin is on the Personal Info page for the family
    And the Admin clicks the Application Type drop down
    And the Admin selects the Paper application option
    And all other mandatory fields on the page have been populated
    When Admin clicks CONTINUE button
    Then the Admin will be navigated to the DOCUMENT UPLOAD page

  Scenario: Hbx Admin uploads and verifies application document
    Given Hbx Admin is on ridp document upload page
    When hbx admin uploads application document and verifies application
    And Hbx Admin logs out
    When Individual visits the Insured portal outside of open enrollment
    Then Individual creates a new HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user registers as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    When the Individual selects “I Disagree”
    And the Individual clicks CONTINUE
    Then Individual should land on Documents upload page
    And Individual logs out
    When an HBX admin exists
    And clicks on Individual in Families tab
    Then Admin should land on ridp document upload page
