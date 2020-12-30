Feature: HBX Admin should be able to send the broker application to pending state

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Then user goes to the Broker Registration form

  Scenario: Broker can enter ACH information
    Given user enters the personal and Broker Agency information
    When user enters the ach routing information
    Then user enters the office locations and phones

  Scenario: HBX Admin sends a Broker Applicant to a pending state and approves through Admin portal
    Given user enters the personal and Broker Agency information
    And user enters the ach routing information
    And user enters the office locations and phones
    When user clicks on Create Broker Agency button
    Then user should see the broker registration successful message
    When that a user with a HBX staff role with HBX Staff subrole exists and is logged in
    Then Hbx Admin is on Broker Index of the Admin Dashboard
    When Hbx Admin is on Broker Index and clicks Broker Applicants
    Then Hbx Admin should see the list of broker applicants
    And Hbx Admin clicks on the current broker applicant show button
    And Hbx Admin should see broker application with carrier appointments
    When Admin clicks on the pending button
    Then Hbx Admin views a successful message